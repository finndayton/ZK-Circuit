include "./mimc.circom";

/*
 * IfThenElse sets `out` to `true_value` if `condition` is 1 and `out` to
 * `false_value` if `condition` is 0.
 *
 * It enforces that `condition` is 0 or 1.
 *
 */

template IfThenElse() {
    signal input condition;
    signal input true_value; // if condition is 1, then 'out' will be this
    signal input false_value; // if condition  if 0, then 'out' will be this
    signal output out;

    //enforce that condition is 0 or 1. 
    condition * (1 - condition) === 0;
    
    signal helper; 
    helper <== true_value * (condition);
    out <== helper + false_value * (1 - condition);
}

/*
 * SelectiveSwitch takes two data inputs (`in0`, `in1`) and produces two ouputs.
 * If the "select" (`s`) input is 1, then it inverts the order of the inputs
 * in the ouput. If `s` is 0, then it preserves the order.
 *
 * It enforces that `s` is 0 or 1.
 */
template SelectiveSwitch() {
    signal input in0;
    signal input in1;
    signal input s;
    signal output out0;
    signal output out1;

    component a;
    a = IfThenElse();
    a.condition <== s;
    a.true_value <== in1;
    a.false_value <== in0;
    out0 <== a.out;

    component b;
    b = IfThenElse();
    b.condition <== s;
    b.true_value <== in0;
    b.false_value <== in1;
    out1 <== b.out;
}
/*
 * Verifies the presence of H(`nullifier`, `nonce`) in the tree of depth 
 * `depth`, summarized by `digest`.
 * This presence is witnessed by a Merle proof provided as
 * the additional inputs `sibling` and `direction`, 
 * which have the following meaning:
 *   sibling[i]: the sibling of the node on the path to this coin
 *               at the i'th level from the bottom.
 *   direction[i]: "0" or "1" indicating whether that sibling is on the left.
 *       The "sibling" hashes correspond directly to the siblings in the
 *       SparseMerkleTree path.
 *       The "direction" keys the boolean directions from the SparseMerkleTree
 *       path, casted to string-represented integers ("0" or "1").
 */
template Spend(depth) {
    signal input digest; //the merkle root hash
    signal input nullifier; 
    signal private input nonce; 
    signal private input sibling[depth]; //
    signal private input direction[depth];

    //1. craft an arithmetic circuit for verifying that a (nullifier, nonce) pair corresponds to A coin in the Merkle tree. 
    //2. reveal the nullifier publically
    //3. use a SNARK to prove the existence of a nonce such that the corresponding coin is in the Merkle tree, in zero-knowledge.

    component hashResult = Mimc2();
    hashResult.in0 <== nullifier;
    hashResult.in1 <== nonce;
    signal our_coin <-- hashResult.out; 


    signal hashes[depth + 1];
    hashes[0] <== our_coin;
    
    component switches[depth];
    component hashers[depth];

    for(var d = 0; d < depth; d++) {
    
       switches[d] = SelectiveSwitch();
       switches[d].s <== direction[d]; //if 0, then we are on the left, thus preserved. if 1, then we are on the right. 
       switches[d].in0 <== hashes[d];
       switches[d].in1 <== sibling[d];

        hashers[d] = Mimc2();
        hashers[d].in0 <== switches[d].out0;
        hashers[d].in1 <== switches[d].out1;
        hashes[d + 1] <== hashers[d].out; //check if this is allowed in circum
    }
    hashes[depth] === digest;
}
// template Spend(depth) {
//     signal input digest; //the Merkle tree root
//     signal input nullifier; // public 
//     signal private input nonce; //private
//     signal private input sibling[depth]; 
//     signal private input direction[depth];

//     // we want to use SelectiveSwitch() to deal with left/right sibling positions
//     //end goal is to verify that the provided nullifier and nonce are valid given digest

//     component mim = Mimc2();
    
//     //remember, the coin is defined as MiMC(nullifier, nonce)
//     mim.in0 <== nullifier;
//     mim.in1 <== nonce;
//     signal initialHash <== mim.out

//     signal hashes[depth + 1];
//     hashes[0] <== initialHash;

//     //all the hashes along the route are stored in sibling[depth]
//     //sibling[0] is the coin layer
//     //the order of MiMC(elm1, elm2) matters, hence the directions consideration

//     for (var i = 0; i < depth; ++i) {
//         component swap = SelectiveSwitch();
//         swap.in0 <== hashes[i];
//         swap.in1 <== sibling[i];
//         swap.s <== direction[i];

//         component mim1 = Mimc2();
//         mim1.in0 <== swap.out0;
//         mim1.in1 <== swap.out1;
//         hashes[i + 1] <== mim1.out;
//     }
//     hashes[depth] === digest;
// } 
// component main = Spend(10);

