#!/usr/bin/python3
import os
import sys
import gzip

class FrequencyFileDescription:
    
    def __init__(self, filename,
               chr_colname = "CHROM", pos_colname = "GENPOS", 
               all0_colname = "ALLELE0", all1_colname = "ALLELE1", 
               a1freq_colname = "A1FREQ"):
        self._filename = filename
        
        self._chr_colname = chr_colname
        self._pos_colname = pos_colname
        self._all0_colname = all0_colname
        self._all1_colname = all1_colname
        self._a1freq_colname = a1freq_colname
        
        self._processed_rows = 0
        self._openFileAndReadHeader()

    # reads a data line and returns an array with chr, pos, all0, all1, a1freq
    def readDataRow(self):
        row = self._file.readline()
        if not row:
            return row #EOF
        self._processed_rows += 1
        return self._parseContentRow(row)
        
    def __del(self):
        self._closeFile()
        
    def _parseHeaderRow(self, header_row):
        self._headers = header_row.split()
        self._chr_col = self._headers.index(self._chr_colname)
        self._pos_col = self._headers.index(self._pos_colname)
        self._all0_col = self._headers.index(self._all0_colname)
        self._all1_col = self._headers.index(self._all1_colname)
        self._a1freq_col = self._headers.index(self._a1freq_colname)
        
    def _parseContentRow(self, content_row):
        fields = content_row.split()
        if fields[self._chr_col] == "X":
            chr = 23
        else:
            chr = int(fields[self._chr_col])
        return [ chr,
                 int(fields[self._pos_col]),
                 fields[self._all0_col],
                 fields[self._all1_col],
                 float(fields[self._a1freq_col])]

    def _openFileAndReadHeader(self):
        self._file = os.popen('pigz -dc ' + self._filename)
        self._parseHeaderRow(self._file.readline())
        
    def _closeFile(self):
        self._file.close()
        
    @property
    def fileName(self):
        return self._filename
        
    @property
    def processedRows(self):
        return self._processed_rows


class FrequencyFileMerger:
    
    def __init__(self, output_filename: str, 
                 file1: FrequencyFileDescription, 
                 file2: FrequencyFileDescription):
        self._output_filename = output_filename
        self._file1 = file1
        self._file2 = file2
        
        self._match = 0
        self._switch = 0
        self._mismatch = 0
        
    def processFiles(self):
        self._output_file = gzip.open(self._output_filename, "wt")
        self._output_file.write("CHROM\tPOS\tSTUDY_FREQ\tREF_FREQ\n")

        line1 = self._file1.readDataRow()
        line2 = self._file2.readDataRow()
        
        while line1 and line2:
            res = self._compareFreqLines(line1, line2)
            if res == 0:
                self._writeOutput(line1, line2)
                line1 = self._file1.readDataRow()
                line2 = self._file2.readDataRow()
            elif res > 0:
                line2 = self._file2.readDataRow()
            elif res < 0:
                line1 = self._file1.readDataRow()
             
        # continue until EOF for correct numbers
        while line1:
            line1 = self._file1.readDataRow()
        while line2:
            line2 = self._file2.readDataRow()
                
        self._output_file.close()
        
    def _compareFreqLines(self, l1, l2):
        chr1 = l1[0]
        chr2 = l2[0]
        if (chr1 < chr2):
            return -1
        elif (chr1 > chr2):
            return 1
        
        # this might break for multi-allelic sites
        pos1 = l1[1]
        pos2 = l2[1]
        if (pos1 < pos2):
            return -1
        elif (pos1 > pos2):
            return 1
        else:
            return 0
        
    def _writeOutput(self, line1, line2):
        l1a1 = line1[2]
        l1a2 = line1[3]
        l1fr = line1[4]

        l2a1 = line2[2]
        l2a2 = line2[3]
        l2fr = line2[4]
        
        ok = False
        if l1a1 == l2a1 and l1a2 == l2a2:
            self._match += 1
            ok = True
        elif l1a1 == l2a2 and l1a2 == l2a1:
            self._switch += 1
            l1fr = 1 - l1fr
            ok = True
        else:
            self._mismatch += 1
            
        if ok:
            chr_str = str(line1[0])
            if chr_str == "23":
                chr_str = "X"
            self._output_file.write(chr_str + "\t" + # chr
                                    str(line1[1]) + "\t" + # pos
                                    str(l1fr) + "\t" + # freq1
                                    str(l2fr) + "\n") # freq2

    @property
    def matchingRegularRows(self):
        return self._match
        
    @property
    def matchingSwitchedRows(self):
        return self._switch
        
    @property
    def nonMatchingRows(self):
        return self._mismatch
            
ref_freq_col = sys.argv[4]
study_freq_file = FrequencyFileDescription(sys.argv[1])
ref_freq_file = FrequencyFileDescription(sys.argv[2], a1freq_colname = ref_freq_col)

merger = FrequencyFileMerger(sys.argv[3], study_freq_file, ref_freq_file)
merger.processFiles()

print("Processed", study_freq_file.processedRows, "rows in", study_freq_file.fileName)
print("Processed", ref_freq_file.processedRows, "rows in", ref_freq_file.fileName)

print("Matched", merger.matchingRegularRows, "regular rows")
print("Matched and switched", merger.matchingSwitchedRows, "rows")
print("Non-matching rows (wrong alleles)", merger.nonMatchingRows)
