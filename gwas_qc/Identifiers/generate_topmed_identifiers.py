#!/usr/bin/python3
import os
import sys
import gzip


class ChrPosAllelesFields:
    
    def __init__(self, chrom, pos, allele0, allele1, fields):
        self._chrom = chrom
        self._pos = pos
        self._allele0 = allele0
        self._allele1 = allele1
        self._fields = fields
        
    @property
    def chrom(self):
        return self._chrom
    
    @property
    def pos(self):
        return self._pos
    
    @property
    def allele0(self):
        return self._allele0
    
    @property
    def allele1(self):
        return self._allele1
    
    @property
    def fields(self):
        return self._fields


class ChromPosAllelesFileReader:

    def __init__(self, filename,
               chr_colname = "CHROM", pos_colname = "GENPOS",
               all0_colname = "REF", all1_colname = "ALT"):
        self._filename = filename

        self._chr_colname = chr_colname
        self._pos_colname = pos_colname
        self._all0_colname = all0_colname
        self._all1_colname = all1_colname

        self._processed_rows = 0
        self._openFileAndReadHeader()
        
    def __del__(self):
        self._closeFile()

    @property
    def fileName(self):
        return self._filename

    @property
    def processedRows(self):
        return self._processed_rows

    @property
    def headerRow(self):
        return self._header_row

    def readDataRow(self):
        """Reads and parses a data line from the input file.
        X and Y are returned as 23/24."""
        row = self._file.readline()
        if not row:
            return None #EOF
        self._processed_rows += 1
        return self._parseContentRow(row)

    def _parseHeaderRow(self, header_row):
        self._header_row = header_row
        self._headers = header_row.split()
        self._chr_col = self._headers.index(self._chr_colname)
        self._pos_col = self._headers.index(self._pos_colname)
        self._all0_col = self._headers.index(self._all0_colname)
        self._all1_col = self._headers.index(self._all1_colname)

    def _parseContentRow(self, content_row):
        fields = content_row.split()
        if fields[self._chr_col] == "X":
            chr = 23
        elif fields[self._chr_col] == "Y":
            chr = 24
        else:
            chr = int(fields[self._chr_col])
        return ChrPosAllelesFields(chr,
                 int(fields[self._pos_col]),
                 fields[self._all0_col],
                 fields[self._all1_col],
                 fields)

    def _openFileAndReadHeader(self):
        self._file = os.popen('pigz -dc ' + self._filename)
        self._parseHeaderRow(self._file.readline())

    def _closeFile(self):
        self._file.close()

class ReferenceFileReader(ChromPosAllelesFileReader):
    
    def __init__(self, filename,
               chr_colname = "CHROM", pos_colname = "GENPOS",
               all0_colname = "REF", all1_colname = "ALT"):
        ChromPosAllelesFileReader.__init__(self, filename, chr_colname, pos_colname,
                       all0_colname, all1_colname)
        

class AssociationFileReader(ChromPosAllelesFileReader):

    def __init__(self, filename,
               chr_colname = "CHROM", pos_colname = "GENPOS",
               all0_colname = "ALLELE0", all1_colname = "ALLELE1",
               id_colname = "ID"):
        ChromPosAllelesFileReader.__init__(self, filename, chr_colname, pos_colname,
                       all0_colname, all1_colname)
        self._id_colname = id_colname
        self._id_col = self.headerRow.split().index(id_colname)

    @property
    def idColumnIndex(self):
        return self._id_col


class AssociationFileMerger:

    def __init__(self, output_filename, study_file, reference_file):
        self._output_filename = output_filename
        self._study_file = study_file
        self._reference_file = reference_file

        self._match = [0]*25
        self._switch = [0]*25
        self._mismatch = [0]*25
        self._not_found = [0]*25

    def processFiles(self):
        if self._output_filename:
            self._output_file = open("| bgzip > " + self._output_filename, "wt")
            self._output_file.write(self._study_file.headerRow + "\n");

        studyLine = self._study_file.readDataRow()
        referenceLine = self._reference_file.readDataRow()

        lineCounter = 0
        print("lines read: 0", end="")

        while studyLine and referenceLine:
            res = self._compareLines(studyLine, referenceLine)
            if res == 0:
                self._writeOutput(studyLine, referenceLine)
                studyLine = self._study_file.readDataRow()
                referenceLine = self._reference_file.readDataRow()
                lineCounter += 1
            elif res > 0:
                referenceLine = self._reference_file.readDataRow()
            elif res < 0:
                self._not_found[studyLine.chrom] += 1
                studyLine = self._study_file.readDataRow()
                lineCounter += 1
            if lineCounter % 10000 == 0:
                print("\rlines read: " + str(lineCounter), end="")

        # continue until EOF for correct numbers (only study file)
        while studyLine:
            studyLine = self._study_file.readDataRow()
            lineCounter += 1

        print("\rtotal lines read: " + str(lineCounter) + "\n")

        if self._output_filename:
            self._output_file.close()

    def _compareLines(self, studyLine, referenceLine):
        if (studyLine.chrom < referenceLine.chrom):
            return -1
        elif (studyLine.chrom > referenceLine.chrom):
            return 1

        if (studyLine.pos < referenceLine.pos):
            return -1
        elif (studyLine.pos > referenceLine.pos):
            return 1

        ref1 = studyLine.allele0
        alt1 = studyLine.allele1
        
        ref2 = referenceLine.allele0
        alt2 = referenceLine.allele1
        
        chrom = studyLine.chrom

        if (ref1 == ref2 and alt1 == alt2):
            self._match[chrom] += 1
            return 0
        elif (ref1 == alt2 and alt1 == ref2):
            self._switch[chrom] += 1
            return 0
        else:
            self._mismatch[chrom] += 1
            
            if ref1 < ref2:
                return -1
            elif ref1 > ref2:
                return 1
            
            if alt1 > alt2:
                return -1
            elif alt1 < alt2:
                return 1
            else:
                raise Exception("unexpected chr/pos/ref/alt constellation")

    def _writeOutput(self, studyLine, referenceLine):
        if self._output_filename:
            novel_fields = studyLine.fields
            novel_fields[self._study_file.idColumnIndex] = self._constructId(referenceLine)
            self._output_file.writelines(["\t".join(novel_fields) + "\n"])
            
    def _constructId(self, referenceLine):
        chrom = str(referenceLine.chrom)
        if chrom == "23":
            chrom = "X"
        elif chrom == "24":
            chrom = "Y"
        return ("chr" + chrom + ":" + str(referenceLine.pos) + ":" 
                + referenceLine.allele0 + ":" + referenceLine.allele1)

    @property
    def matchingRegularRowsPerChr(self):
        return self._match

    @property
    def matchingSwitchedRowsPerChr(self):
        return self._switch

    @property
    def nonMatchingRowsPerChr(self):
        return self._mismatch

    @property
    def rowsNotFoundPerChr(self):
        return self._not_found

if len(sys.argv) < 2:
    print("Usage: " + sys.argv[0] + " <study_fn> <reference_fn> [<output_fn>]\n")
    sys.exit(9)

study_fn = sys.argv[1]
reference_fn = sys.argv[2]

study_file = AssociationFileReader(study_fn)
reference_file = ReferenceFileReader(reference_fn)

if len(sys.argv) > 3:
    out_fn = sys.argv[3]
    print("Process '" + study_fn + "' to '" + out_fn)
else:
    out_fn = None
    print("Compare '" + study_fn + "' to reference")

print("Using reference: '" + reference_fn)

merger = AssociationFileMerger(out_fn, study_file, reference_file)
merger.processFiles()

print("Matched (regular): ", merger.matchingRegularRowsPerChr)
print("Matched (switch):  ", merger.matchingSwitchedRowsPerChr)
print("Non-matching (wrong alleles): ", merger.nonMatchingRowsPerChr)
print("Study variant not found: ", merger.rowsNotFoundPerChr)
