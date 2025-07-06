# ArticleEdits.jl
# This package is designed to assist with managing LaTeX documents and associated files,
# specifically tailored for preparing uploads for journal publications. It provides tools
# for extracting, organizing, and processing picture files, combining TeX files, and
# identifying changes between file versions.

module ArticleEdits
using SHA

include("getEpsNames.jl")
include("oneFileExtractTex.jl")
include("revisonChanges.jl")
#oneFileExtractTex
export getNamesOfUncommentedPicFiles, getUncommentedTexFiles
export getAllUncommentedPicFileNames, copyUncommentedPicFiles
export createOneTexFile
#getEpsNames
export getNamesOfPicFiles, getNamesOfTexFiles, getAllPicFileNames
export copyPicSvgFiles
#revisonChanges
export getTotallyNewFiles, getChangedUnChangedFiles
export getFilesToUpload, copyFilesToUpload, copyUnchangedFiles



end # module ArticleEdits
