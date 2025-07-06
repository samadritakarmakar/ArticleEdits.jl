""" 
Extracts names of picture files (e.g., eps, png, jpg, jpeg) that are not commented out in the given TeX file.

Arguments:
- `texFile::String`: Path to the TeX file.
- `types::Vector{String}`: List of picture file extensions to search for (default: ["eps", "png", "jpg", "jpeg"]).

Returns:
- `Vector{String}`: A list of picture file paths found in the TeX file.
"""
function getNamesOfPicFiles(texFile::String, types = ["eps", "png", "jpg", "jpeg"])
    dirnameTex = dirname(texFile)
    # Read the tex file
    texFileContent = read(texFile, String)
    # Get the names of the pic files
    picFiles = String[]
    for type in types
            ex = Regex("\\{.*\\.\\Q$type\\E\\}")
            #ex = r"\{.*\.eps\}"
            println("ex: ", ex)
            for matching = eachmatch(ex, texFileContent)
                push!(picFiles, joinpath(dirnameTex, matching.match[2:end-1]))
                println("picFiles: \n", picFiles)
            end
    end
    return picFiles 
end

""" 
Extracts names of TeX files that are not commented out in the given base TeX file.

Arguments:
- `texFileBase::String`: Path to the base TeX file.

Returns:
- `Vector{String}`: A list of TeX file paths found in the base TeX file.
"""
function getNamesOfTexFiles(texFileBase::String)
    dirnameTex = dirname(texFileBase)
    texFileContent = read(texFileBase, String)
    texFiles = String[]
    for matching = eachmatch(r"\{.*\.tex\}", texFileContent)
        push!(texFiles, joinpath(dirnameTex, matching.match[2:end-1]))
    end
    return texFiles
end


""" 
Extracts all picture file names (including those in referenced TeX files) that are not commented out.

Arguments:
- `texFileBase::String`: Path to the base TeX file.

Returns:
- `Vector{String}`: A list of all picture file paths found in the base TeX file and its referenced TeX files.
"""
function getAllPicFileNames(texFileBase::String)
    texFiles = getNamesOfTexFiles(texFileBase)
    picFiles = String[]
    picFiles = getNamesOfPicFiles(texFileBase)
    for texFile in texFiles
        picFiles = vcat(picFiles, getNamesOfPicFiles(texFile))
    end
    return picFiles
end


""" 
Copies picture files (with optional conversion of .eps to .svg) that are not commented out to the target directory.

Arguments:
- `texFileBase::String`: Path to the base TeX file.
- `targetDir::String`: Directory where the picture files will be copied.
- `excludeDirs::String[]`: List of directory names to exclude from copying.
"""
function copyPicSvgFiles(texFileBase::String, targetDir::String; excludeDirs = String[])
    picFiles = getAllPicFileNames(texFileBase)
    for picFile in picFiles
        if !any(x -> occursin(x, picFile), excludeDirs)
            #replace .eps by .svg
            picFile = replace(picFile, r"\.eps$" => ".svg")
            cp(picFile, joinpath(targetDir, basename(picFile)))
        end
    end
end