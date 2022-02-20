const { docopt } = require("docopt");
const { mimc2 } = require("./mimc.js");
const { SparseMerkleTree } = require("./sparse_merkle_tree.js");
const fs = require("fs");
const doc = `Usage:
  compute_spend_inputs.js [options] <depth> <transcript> <nullifier>
  compute_spend_inputs.js -h | --help

Options:
  -o <file>     name of the created witness file [default: input.json]
  -h --help     Print this message

Arguments:
   <depth>       The number of non-root layers in the merkle tree.
   <transcript>  The file containing transcript of all coins.
                 A file with a line for each coin.
                 Each coin is either a single number (the coin
                 itself) or it can be two space-separated number, which are, in
                 order, the nullifier and the nonce for the coin.

                 Example:

                     1839475893
                     1984375234 2983475298
                     3489725451 9834572345
                     3452345234

   <nullifier>   The nullifier to print a witness of validity for.
                 Must be present in the transcript.
`

/*
 * Computes inputs to the Spend circuit.
 *
 * Inputs:
 *   depth: the depth of the merkle tree being used.
 *   transcript: A list of all coins added to the tree.
 *               Each item is an array.
 *               If the array has one element, then that element is the coin.
 *               Otherwise the array will have two elements, which are, in order:
 *                 the nullifier and
 *                 the nonce
 *               This list will contain **no** duplicate nullifiers or coins.
 *   nullifier: The nullifier to print inputs to validity verifier for.
 *              This nullifier will be one of the nullifiers in the transcript.
 *
 * Return:
 *   an object of the form:
 * {
 *   "digest"            : ...,
 *   "nullifier"         : ...,
 *   "nonce"             : ...,
 *   "sibling[0]"        : ...,
 *   "sibling[1]"        : ...,
 *      ...
 *   "sibling[depth-1]"  : ...,
 *   "direction[0]"      : ...,
 *   "direction[1]"      : ...,
 *      ...
 *   "direction[depth-1]": ...,
 * }
 * where each ... is a string-represented field element (number)
 * notes about each:
 *   "digest": the digest for the whole tree after the transcript is
 *                  applied.
 *   "nullifier": the nullifier for the coin being spent.
 *   "nonce": the nonce for that coin
 *   "sibling[i]": the sibling of the node on the path to this coin
 *                 at the i'th level from the bottom.
 *   "direction[i]": "0" or "1" indicating whether that sibling is on the left.
 *       The "sibling" hashes correspond directly to the siblings in the
 *       SparseMerkleTree path.
 *       The "direction" keys the boolean directions from the SparseMerkleTree
 *       path, casted to string-represented integers ("0" or "1").
 */
function computeInput(depth, transcript, nullifier) {
    // TODO
    // this function computes the input needed for our circuit. 
    // transcript is a list of tuples or singular values
    // loop through transcript. If coin (1 value), add to the tree. If tuple (2 elements) hash and then add to the tree
    // we are also passed in a nullifier, find the nonce associated with this nullifier. Perform a check in the loop to find this nonce. 
    result = {};
    let merkleTree = new SparseMerkleTree(depth);
    for (let item of transcript){
      if (item.length == 2) {
        let hash = mimc2(item[0], item[1]);
        merkleTree.insert(hash);
        if (item[0] == nullifier) {
          result.nullifier = item[0];
          result.nonce = item[1]
        }
      } else {
        merkleTree.insert(item);
      }      
    
      //add the sibling and direction info to result for this coin.
    }
    let coin = mimc2(result.nullifier, result.nonce);
    let path = merkleTree.path(coin); //path is an array of (sibling, direction) pairs
    for (let i = 0; i < path.length; i++){
       let sibling = path[i][0];
       let direction = path[i][1] ? "1" : "0";
       result[`sibling[${i}]`] = sibling;
       result[`direction[${i}]`] = direction; 
    }
    result.digest = merkleTree.digest;
    return result;
}

module.exports = { computeInput };

// If we're not being imported
if (!module.parent) {
    const args = docopt(doc);
    const transcript =
        fs.readFileSync(args['<transcript>'], { encoding: 'utf8' } )
        .split(/\r?\n/)
        .filter(l => l.length > 0)
        .map(l => l.split(/\s+/));
    const depth = parseInt(args['<depth>']);
    const nullifier = args['<nullifier>'];
    const input = computeInput(depth, transcript, nullifier);
    fs.writeFileSync(args['-o'], JSON.stringify(input) + "\n");
}
