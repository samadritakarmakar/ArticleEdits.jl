using SHA
function file_hash(path)
    open(path) do io
        return sha1(io)
    end
end

"""
Identifies files that exist in the new directory but not in the old directory.

Arguments:
- `newPicsAndFigsDir::String`: Path to the directory containing new files.
- `oldPicsAndFigsDir::String`: Path to the directory containing old files.

Returns:
- `Vector{String}`: A list of file names that are present in the new directory but absent in the old directory.
"""
function getTotallyNewFiles(newPicsAndFigsDir::String, oldPicsAndFigsDir::String)
    newFiles = readdir(newPicsAndFigsDir, join=false)
    oldFiles = readdir(oldPicsAndFigsDir, join=false)
    return setdiff(newFiles, oldFiles)
end
    
""" 
Identifies changed and unchanged files between the new and old directories based on file size and optional hash comparison.

Arguments:
- `newPicsAndFigsDir::String`: Path to the directory containing new files.
- `oldPicsAndFigsDir::String`: Path to the directory containing old files.
- `useHash::Bool`: Whether to use hash comparison for detecting changes (default: true).
- `skipEpsHash::Bool`: Whether to skip hash comparison for `.eps` files (default: true).

Returns:
- `Tuple{Set{String}, Set{String}}`: A tuple containing:
  - `changedFiles`: Set of file names that have changed.
  - `unchangedFiles`: Set of file names that remain unchanged.
"""
function getChangedUnChangedFiles(newPicsAndFigsDir::String, oldPicsAndFigsDir::String; useHash::Bool=true, skipEpsHash::Bool=true)
    newFiles = readdir(newPicsAndFigsDir, join=false)
    oldFiles = readdir(oldPicsAndFigsDir, join=false)
    changedFilesBySize = Set{String}()
    changedFilesByHash = Set{String}()
    newFilesStatsVec = stat.(joinpath.(newPicsAndFigsDir, newFiles))
    oldFilesStatsVec = stat.(joinpath.(oldPicsAndFigsDir, oldFiles))
    for (i, newFile) in enumerate(newFiles)
        newFileHash = file_hash(joinpath(newPicsAndFigsDir, newFile))
        for (j, oldFile) in enumerate(oldFiles)
            if newFile == oldFile 
                if newFilesStatsVec[i].size != oldFilesStatsVec[j].size
                    push!(changedFilesBySize, newFile)
                end
                oldFileHash = file_hash(joinpath(oldPicsAndFigsDir, oldFile))
                if newFileHash != oldFileHash && useHash
                    if !endswith(newFile, ".eps")
                        push!(changedFilesByHash, newFile)
                    elseif !skipEpsHash 
                        # EPS files changes hashes every time they are regenerated
                        # so we may skip hashes for them
                        push!(changedFilesByHash, newFile)
                    end
                end
            end
        end
    end
    changedFiles = union(changedFilesBySize, changedFilesByHash)
    unchangedFiles = setdiff(oldFiles, changedFiles)
    return changedFiles, unchangedFiles
end

#=function getUnchangedFiles(newPicsAndFigsDir::String, oldPicsAndFigsDir::String; useHash::Bool=true, skipEpsHash::Bool=false)
    newFiles = readdir(newPicsAndFigsDir, join=false)
    oldFiles = readdir(oldPicsAndFigsDir, join=false)
    unchangedFiles = Set{String}()
    newFilesStatsVec = stat.(joinpath.(newPicsAndFigsDir, newFiles))
    oldFilesStatsVec = stat.(joinpath.(oldPicsAndFigsDir, oldFiles))
    for (i, newFile) in enumerate(newFiles)
        for (j, oldFile) in enumerate(oldFiles)
            if newFile == oldFile 
                if newFilesStatsVec[i].size == oldFilesStatsVec[j].size
                    if useHash 
                        newFileHash = file_hash(joinpath(newPicsAndFigsDir, newFile))
                        oldFileHash = file_hash(joinpath(oldPicsAndFigsDir, oldFile))
                        if !(skipEpsHash && endswith(newFile, ".eps"))
                            # EPS files changes hashes every time they are regenerated
                              # so we may skip hashes for them
                            if newFileHash == oldFileHash
                                push!(unchangedFiles, newFile)
                            end
                        elseif !skipEpsHash
                            push!(unchangedFiles, newFile)
                        end
                    end
                end
            end
        end
    end
    return unchangedFiles
end=#

            



""" 
Identifies files to upload by combining totally new files and changed files, while also returning unchanged files.

Arguments:
- `newPicsAndFigsDir::String`: Path to the directory containing new files.
- `oldPicsAndFigsDir::String`: Path to the directory containing old files.
- `useHash::Bool`: Whether to use hash comparison for detecting changes (default: true).
- `skipEpsHash::Bool`: Whether to skip hash comparison for `.eps` files (default: true).

Returns:
- `Tuple{Set{String}, Set{String}}`: A tuple containing:
  - `filesToUpload`: Set of file names to upload (new or changed files).
  - `unChangedFiles`: Set of file names that remain unchanged.
"""
function getFilesToUpload(newPicsAndFigsDir::String, oldPicsAndFigsDir::String; 
                          useHash::Bool=true, skipEpsHash::Bool=true)
    totallyNewFiles = getTotallyNewFiles(newPicsAndFigsDir, oldPicsAndFigsDir)
    changedFiles, unChangedFiles = getChangedUnChangedFiles(newPicsAndFigsDir, oldPicsAndFigsDir, 
                                                   useHash=useHash, skipEpsHash=skipEpsHash)
    filesToUpload = union(totallyNewFiles, changedFiles)
    return filesToUpload, unChangedFiles
end

""" 
Copies files to upload (new or changed files) from the new directory to the target directory.

Arguments:
- `copyToDir::String`: Path to the target directory where files will be copied.
- `newPicsAndFigsDir::String`: Path to the directory containing new files.
- `oldPicsAndFigsDir::String`: Path to the directory containing old files.
- `useHash::Bool`: Whether to use hash comparison for detecting changes (default: true).
- `skipEpsHash::Bool`: Whether to skip hash comparison for `.eps` files (default: true).

Returns:
- `Nothing`: Performs the copy operation without returning a value.
"""
function copyFilesToUpload(copyToDir::String, newPicsAndFigsDir::String, oldPicsAndFigsDir::String; 
                           useHash::Bool=true, skipEpsHash::Bool=true)
    filesToUpload, _ = getFilesToUpload(newPicsAndFigsDir, oldPicsAndFigsDir, useHash=useHash, 
                                                     skipEpsHash=skipEpsHash)
                                                     
    for file in filesToUpload
        srcChanged = joinpath(newPicsAndFigsDir, file)
        dest = joinpath(copyToDir, file)
        if isfile(srcChanged)
            cp(srcChanged, dest, force=true, follow_symlinks=true)
        else
            @warn "File $srcChanged does not exist, skipping copy."
        end
    end
    @info "Copied $(length(filesToUpload)) changed files to $copyToDir"
    return nothing
end

""" 
Copies unchanged files from the old directory to the target directory.

Arguments:
- `copyToDir::String`: Path to the target directory where files will be copied.
- `newPicsAndFigsDir::String`: Path to the directory containing new files.
- `oldPicsAndFigsDir::String`: Path to the directory containing old files.
- `useHash::Bool`: Whether to use hash comparison for detecting unchanged files (default: true).
- `skipEpsHash::Bool`: Whether to skip hash comparison for `.eps` files (default: true).

Returns:
- `Nothing`: Performs the copy operation without returning a value.
"""
function copyUnchangedFiles(copyToDir::String, newPicsAndFigsDir::String, oldPicsAndFigsDir::String; 
                           useHash::Bool=true, skipEpsHash::Bool=true)
    _, unChangedFiles = getFilesToUpload(newPicsAndFigsDir, oldPicsAndFigsDir, useHash=useHash, 
                                         skipEpsHash=skipEpsHash)
    for file in unChangedFiles
        srcUnchanged = joinpath(oldPicsAndFigsDir, file)
        dest = joinpath(copyToDir, file)
        if isfile(srcUnchanged)
            cp(srcUnchanged, dest, force=true, follow_symlinks=true)
        else
            @warn "File $srcUnchanged does not exist, skipping copy."
        end
    end
    @info "Copied $(length(unChangedFiles)) unchanged files to $copyToDir"
    return nothing
end