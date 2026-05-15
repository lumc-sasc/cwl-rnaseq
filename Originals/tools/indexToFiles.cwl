cwlVersion: v1.2
class: ExpressionTool
label: "Index Directory to Index files list"

inputs:
    indexFiles:
        type: Directory
        loadListing: deep_listing

outputs:
    indexFiles:
        type: File[]
        

requirements:
    InlineJavascriptRequirement: {}

expression: |
  ${ 
    function flattenDirectory(listing) {
        if (!listing) return [];
        let files = [];
        listing.forEach(item => {
            if (item.class === "File") {
                files.push(item);
            } else if (item.class === "Directory") {
                files = files.concat(flattenDirectory(item.listing));
            }
        });
        return files;
    }

    return { indexFiles: flattenDirectory(inputs.indexFiles.listing) };
  }