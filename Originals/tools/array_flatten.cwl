cwlVersion: v1.2
class: ExpressionTool
label: "Array Flattener"

inputs:
    inputData:
        type: Any?
        doc: "Single value, array, or nested array."
    noNull:
        type: boolean?
        default: false
        doc: "When true, remove null values from the arrays."

outputs:
    flatArray:
        type: Any[]
        doc: "Always a flat array."

requirements:
    InlineJavascriptRequirement: {}

expression: |
    ${ 
        function flattenAndClean(x, removeNull) {
            if (x === null && removeNull) return [];
            if (Array.isArray(x)) return x.flatMap(e => flattenAndClean(e, removeNull));
            return [x];
        }

        return {
            flatArray: flattenAndClean(inputs.inputData, inputs.noNull)
        };
    }