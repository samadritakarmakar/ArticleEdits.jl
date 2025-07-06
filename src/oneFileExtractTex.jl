#include("getEpsNames.jl")

""" 
Extracts names of picture files (e.g., eps, png, jpg, jpeg) that are not commented out in the given TeX file.

Arguments:
- `texFile::String`: Path to the TeX file.
- `types::Vector{String}`: List of picture file extensions to search for (default: ["eps", "png", "jpg", "jpeg"]).

Returns:
- `Vector{String}`: A list of picture file paths found in the TeX file that are not commented out.
"""
function getNamesOfUncommentedPicFiles(texFile::String, types = ["eps", "png", "jpg", "jpeg"])
    dirnameTex = dirname(texFile)
    # Read the tex file
    texFileContent = read(texFile, String)
    # Get the names of the pic files
    picFiles = Vector{String}()
    commentedPicFiles = Set{String}()
    rejectedPicFiles = Set{String}()
    for type in types
        commentedEx = Regex("\\%.*\\{.*\\.\\Q$type\\E\\}")
        uncommentedEx = Regex("\\{.*\\.\\Q$type\\E\\}")
        #println("commentedEx: ", commentedEx)
        for matchingCommented = eachmatch(commentedEx, texFileContent)
            stringMatchingCommented = matchingCommented.match
            #get the pic file name
            commentedPicFile = match(uncommentedEx, stringMatchingCommented).match[2:end-1]
            #println("commentedPicFile: ", commentedPicFile)
            push!(commentedPicFiles, commentedPicFile)
        end
        for matching = eachmatch(uncommentedEx, texFileContent)
            picFile = matching.match[2:end-1]
            if picFile ∉ commentedPicFiles
                push!(picFiles, joinpath(dirnameTex, picFile))
            else
                push!(rejectedPicFiles, picFile)
            end
        end
    end
    return picFiles
end

""" 
Extracts names of TeX files that are not commented out in the given base TeX file.

Arguments:
- `texFileBase::String`: Path to the base TeX file.

Returns:
- `Vector{String}`: A list of TeX file paths found in the base TeX file that are not commented out.
"""
function getUncommentedTexFiles(texFileBase::String)
    dirnameTex = dirname(texFileBase)
    #println("texFileBase: ", texFileBase)   
    texFileContent = read(texFileBase, String)
    texFiles = Vector{String}()
    texFileCommented = Set{String}()
    commentedEx = r"\%.*\.tex\}"
    uncommentedEx = r"\{.*\.tex\}"
    for matchingCommented = eachmatch(commentedEx, texFileContent)
        stringMatchingCommented = matchingCommented.match
        #println("stringMatchingCommented: ", stringMatchingCommented)
        #get the tex file name
        commentedTexFile = match(uncommentedEx, stringMatchingCommented).match[2:end-1]
        #println("commentedTexFile: ", commentedTexFile)
        push!(texFileCommented, commentedTexFile)
    end
    for matching = eachmatch(uncommentedEx, texFileContent)
        texFile = matching.match[2:end-1]
        if texFile ∉ texFileCommented
            push!(texFiles, joinpath(dirnameTex, texFile))
        end
    end
    return texFiles
end

""" 
Extracts all picture file names those in referenced TeX files that are not commented out.

Arguments:
- `texFileBase::String`: Path to the base TeX file.

Returns:
- `Vector{String}`: A list of all picture file paths found in the base TeX file and its referenced TeX files that are not commented out.
"""
function getAllUncommentedPicFileNames(texFileBase::String)
    texFiles = getUncommentedTexFiles(texFileBase)
    picFiles = Vector{String}()
    picFiles = getNamesOfUncommentedPicFiles(texFileBase)
    for texFile in texFiles
        #union!(picFiles, getNamesOfUncommentedPicFiles(texFile))
        append!(picFiles, getNamesOfUncommentedPicFiles(texFile))
    end
    return picFiles
end

""" 
Copies picture files that are not commented out to the target directory.

Arguments:
- `texFileBase::String`: Path to the base TeX file.
- `targetDir::String`: Directory where the picture files will be copied.
- `types::Vector{String}`: List of picture file extensions to search for (default: ["eps", "png", "jpg", "jpeg"]).
- `excludeDirs::Vector{String}`: List of directory names to exclude from copying.

Returns:
- `Nothing`: Performs the copy operation without returning a value.
"""
function copyUncommentedPicFiles(texFileBase::String, targetDir::String, types = ["eps", "png", "jpg", "jpeg"]; excludeDirs = String[])
    picFiles = getAllUncommentedPicFileNames(texFileBase)
    for picFile in picFiles
        if !any(x -> occursin(x, picFile), excludeDirs)
            cp(picFile, joinpath(targetDir, basename(picFile)))
        end
    end
end

""" 
Combines the content of the base TeX file and its referenced TeX files into a single TeX file content.

Arguments:
- `texFileBase::String`: Path to the base TeX file.

Returns:
- `String`: The combined content of the base TeX file and its referenced TeX files.
"""
function createOneTexFile(texFileBase::String)
    texFiles = getUncommentedTexFiles(texFileBase)
    #println("texFiles: ", texFiles)
    texFileContent = read(texFileBase, String)
    for texFile in texFiles
        #println("texFile: ", texFile)   
        internalTexFileContent = createOneTexFile(texFile)
        regTexFile = Regex("[\\\\]input\\{$(texFile[4:end])\\}")
        #println("matched textfile", match(regTexFile, texFileContent))
        #println("regTexFile: ", regTexFile)
        texFileContent = replace(texFileContent, regTexFile => internalTexFileContent)
        display(texFileContent)
    end
    return texFileContent
end

""" 
Creates a single TeX file by combining the content of the base TeX file and its referenced TeX files, removing comments, and updating picture file paths.

Arguments:
- `texFileBase::String`: Path to the base TeX file.
- `targetDir::String`: Directory where the resulting TeX file will be saved.
- `targetFileName::String`: Name of the resulting TeX file.

Returns:
- `Nothing`: Writes the combined TeX file content to the specified target directory and file name.
"""
function createOneTexFile(texFileBase::String, targetDir::String, targetFileName::String)
    texFileContent = createOneTexFile(texFileBase)
    #remove all comments
    texFileContent = replace(texFileContent, r"\%.*\n" => "")
    #get all uncommented pic files
    picFiles = getAllUncommentedPicFileNames(texFileBase)
    println("picFiles: ", basename.(picFiles))
    for picFile in picFiles
        picFileBaseName = basename(picFile)
        texFileContent = replace(texFileContent, picFile[4:end] => picFileBaseName)
    end
    write(joinpath(targetDir, targetFileName), texFileContent)
    return nothing
end
