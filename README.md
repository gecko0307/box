Box
===
Box is a simple uncompressed archive file format, a container for multiple files with directory structure. The reason I've created this is mainly discontent with Tar format, which is a standard file container under Unix. The main drawback of Tar, IMHO, is that it doesn't define any filename encoding info, simply copying raw strings from FS, assuming they are ASCII. So copying files with non-latin names from one system to another with Tar can be very frustrating problem. I'm an UTF-8 adept, so I decided to create my own archive format that would explicitly store all text in UTF-8. Because Box is written in D, all necessary system-specific encoding and decoding is done by D's standard library, which is fully based on UTF-8.

Features
--------
* Easy to use
* Cross-platform
* Respects non-latin filenames
* Generates slightly smaller files than Tar
* Simple and straightforward, easy to decode and encode in any language with native Unicode support
* Can be used as an asset container for game engines

Current limitations
-------------------
Eventually these issues may be solved:

* Doesn't keep file attributes (such as modification date and access permissions)
* Doesn't keep empty directories
* Dealing with large files is not efficient (no bufferization, files are loaded in memory entirely)
* Very basic format - probably lacks most of your desired features (symlinks, EA, concatenation, encryption, etc).