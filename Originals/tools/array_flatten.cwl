cwlVersion: v1.2
class: ExpressionTool
label: "Array Flattener"

inputs:
    inputData:
        type: Any?
        doc: "Single value, array, or nested array."

outputs:
    flatArray:
        type: Any[]
        doc: "Always a flat array."

expression: |
    ${ 
        return { 
            flatArray: Array.isArray(inputs.inputData) ? inputs.inputData.flat(Infinity) : [inputs.inputData] 
        }; 
    }