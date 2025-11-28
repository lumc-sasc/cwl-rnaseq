cwlVersion: v1.2
class: ExpressionTool
label: ""
doc: ""

inputs:
    jsonFile:
        type: File
        loadContents: true
    readLocation:
        type: Directory
        doc: "The directory containing the reads referred to in the samples. Please use the first directory in the path referred to as input value."

outputs:
    jsonDict:
        type:
            type: array
            items:
                type: record
                name: sample_record
                fields:
                    - name: id
                      type: string
                    - name: readgroups
                      type:
                          type: array
                          items:
                              type: record
                              name: readgroup_record
                              fields:
                                  - name: id
                                    type: string
                                  - name: R1
                                    type: File
                                  - name: R1_md5
                                    type: string?
                                  - name: R2
                                    type: File?
                                  - name: R2_md5
                                    type: string?
                                  - name: lib_id
                                    type: string
        doc: "Sample definitions with loose sample id and nested readgroups."

requirements:
    InlineJavascriptRequirement: {}

expression: |
    ${
    function findCommonPrefixParts(p1, p2) {
        var parts1 = p1.split('/');
        var parts2 = p2.split('/');
        var i = 0;
        while(i < parts1.length && i < parts2.length && parts1[i] === parts2[i]) {
            i++;
        }
        return parts1.slice(0, i);
    }

    function rewriteLocation(baseDir, filePath) {
        var baseParts = baseDir.split('/');
        var fileParts = filePath.split('/');

        var commonParts = findCommonPrefixParts(baseDir, filePath);
        var overlapLength = commonParts.length + 1;

        // slice fileParts after overlap to get relative parts
        var relativeParts = fileParts.slice(overlapLength);

        // join cleaned baseDir and relative parts with single slash
        var newPath = baseParts.join('/') + '/' + relativeParts.join('/');
        newPath = newPath.replace(/\/+/g, '/');
        if (!newPath.startsWith('/')) {
            newPath = '/' + newPath;
        }
        return 'file://' + newPath;
    }

    var samples = JSON.parse(inputs.jsonFile.contents).samples;
    var basePath = inputs.readLocation.location.replace(/^file:\/\//, '');

    samples.forEach(sample => {
        sample.readgroups.forEach(rg => {
            var r1path = (typeof rg.R1 === 'string') ? rg.R1 : rg.R1.location;
            var r1newLoc = rewriteLocation(basePath, r1path);
            rg.R1 = {class: 'File', location: r1newLoc, basename: r1newLoc.split('/').pop()};

            if (rg.R2) {
                var r2path = (typeof rg.R2 === 'string') ? rg.R2 : rg.R2.location;
                var r2newLoc = rewriteLocation(basePath, r2path);
                rg.R2 = {class: 'File', location: r2newLoc, basename: r2newLoc.split('/').pop()};
            }
        });
    });

    return {jsonDict: samples};
    }
