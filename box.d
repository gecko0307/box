module box;

import std.stdio;
import std.path;
import std.file;
import std.bitmanip;
import std.system;
import std.array;

bool validDir(string dir)
{
    if (exists(dir))
        return isDir(dir);
    else
        return false;
}

bool validFile(string f)
{
    if (exists(f))
        return isFile(f);
    else
        return false;
}

struct BoxEntry
{
    ulong offset;
    ulong size;
}

ubyte[] bytesFrom(T)(T val)
{
    ubyte[] bytes = new ubyte[val.sizeof];
    write!(T, Endian.littleEndian)(bytes, val, 0);
    return bytes;
}

T read(T, R)(Endian endianness, R r)
{
    if (endianness == Endian.bigEndian)
        return std.bitmanip.read!(T,Endian.bigEndian,R)(r);
    else
        return std.bitmanip.read!(T,Endian.littleEndian,R)(r);
}

void pack(string inpDir, string boxFile)
{
    if (!validDir(inpDir))
    {
        writefln("Error: \"%s\" does not exist or is not a directory", inpDir);
        return;
    }

    // Stage 1. Read filenames
    string[] filenames;
    BoxEntry[string] entries;
    ulong totalSize = 0;
    foreach(string name; dirEntries(inpDir, SpanMode.depth))
    {
        if (isFile(name))
        {
            filenames ~= name;
            ulong size = getSize(name);
            totalSize += size;
            entries[name] = BoxEntry(0UL, size);
        }
    }

    // Check total size
    enum ulong fourGb = 4UL * (2UL^^30UL);
    writefln("Total size of packed files: %s byte(s)", totalSize);
    if (totalSize >= fourGb)
    {
        writeln("Warning: total output size is going to be larger that 4 Gb!");
        // TODO: user confirmation to proceed
    }

    // Stage 2. Calculate offsets

    // Calc initial data offset
    ulong dataOffset = 4UL + 8UL;
    foreach(filename; filenames)
    {
        dataOffset += 4UL; // filename size
        dataOffset += filename.length;
        dataOffset += 8UL; // data offset
        dataOffset += 8UL; // data size
    }

    // Fill in entry offsets
    ulong offset = dataOffset;
    foreach(filename; filenames)
    {
        entries[filename].offset = offset;
        offset += entries[filename].size;
    }

    // Stage 3. Write header
    auto box = File(boxFile, "w");
    box.write("BOXF"); // magic number
    box.rawWrite(bytesFrom(cast(ulong)filenames.length));
    foreach(filename; filenames)
    {
        string filename2 = replace(filename, "\\", "/");
        box.rawWrite(bytesFrom(cast(uint)filename2.length));
        box.write(filename2);
        box.rawWrite(bytesFrom(entries[filename].offset));
        box.rawWrite(bytesFrom(entries[filename].size));
    }

    // Stage 4. Write data
    foreach(filename; filenames)
    {
        // TODO: do not read entire file into memory, use byChunk instead
        box.rawWrite(cast(ubyte[])std.file.read(filename));
    }

    box.close();
}

void unpack(string inpFile, string outDir)
{
    if (!validFile(inpFile))
    {
        writefln("Error: \"%s\" does not exist or is not a file", inpFile);
        return;
    }

    if (exists(outDir))
    {
        if (!isDir(outDir))
        {
            writefln("Error: \"%s\" does not exist or is not a directory", outDir);
            return;
        }
    }

    auto f = File(inpFile, "r");
    ubyte[4] magic;
    f.rawRead(magic);
    // TODO: assert magic

    ubyte[8] buf;
    f.rawRead(buf);
    ulong numFiles = read!(ulong, ubyte[])(Endian.littleEndian, buf);

    BoxEntry[string] entries;

    ubyte[4] buf2;
    foreach(i; 0..numFiles)
    {
        f.rawRead(buf2);
        uint filenameSize = read!(uint, ubyte[])(Endian.littleEndian, buf2);
        ubyte[] filenameBytes = new ubyte[filenameSize];
        f.rawRead(filenameBytes);
        string filename = cast(string)filenameBytes;
        f.rawRead(buf);
        ulong offset = read!(ulong, ubyte[])(Endian.littleEndian, buf);
        f.rawRead(buf);
        ulong size = read!(ulong, ubyte[])(Endian.littleEndian, buf);

        entries[filename] = BoxEntry(offset, size);
    }

    foreach(filename, e; entries)
    {
        writeln(filename);
        f.seek(e.offset);
        // TODO: read by chunks
        ubyte[] data = new ubyte[cast(size_t)e.size];
        f.rawRead(data);
        string filename2 = replace(filename, "\\", "/");
        string outPath = outDir ~ "/" ~ filename2;
        string outDirPath = dirName(outPath);
        if (!exists(outDirPath))
            mkdirRecurse(outDirPath);
        std.file.write(outPath, data);
    }

    f.close();
}

void main(string[] args)
{
    if (args.length < 2)
    {
        writeln ("Usage:");
        writefln("  %s inputDir [outputFile]", args[0]);
        writefln("  %s inputFile [outputDir]", args[0]);
        return;
    }

    string input = args[1];

    if (validDir(input))
    {
        string boxFile;

        if (args.length >= 3)
            boxFile = args[2];
        else
            boxFile = input.baseName ~ ".box";
    
        pack(input, boxFile);
    }
    else
    {
        string outDir;

        if (args.length >= 3)
            outDir = args[2];
        else
            outDir = "./";

        unpack(input, outDir);
    }
}

