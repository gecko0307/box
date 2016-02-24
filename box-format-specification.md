Box file format specification
-----------------------------
Box file consists of three sections: header, index and data. 

Primitive data types:
* uint - 4-byte unsigned integer, little-endian
* ulong - 8-byte unsigned integer, little-endian

Header
------
* 4 bytes - magic string "BOXF"
* 8 bytes (ulong) - number of packed files

Index
-----
A list of file entries. Total number of entries is determined in header section (number of packed files).

A file entry consists of the following:
* 4 bytes (uint) - file path size in bytes
* N bytes - file path in UTF-8 encoding. Path is relative to root directory (that is, a directory contents of which was packed in *.box file). Directory separator character is "/" under all platforms
* 8 bytes (ulong) - file byte offset relative to beginning of the *.box file
* 8 bytes (ulong) - file size in bytes

Data
----
Raw data for packed files. Offsets in the index point to positions in this section. There are no physical boundaries or marks separating one file from another.

