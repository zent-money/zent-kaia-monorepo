export const ABI_ESCROW = [
  { type:"function", name:"createPass", stateMutability:"nonpayable",
    inputs:[{name:"token",type:"address"},{name:"amount",type:"uint256"},{name:"hashSecret",type:"bytes32"},{name:"expiry",type:"uint64"}], outputs:[{type:"uint256"}] },
  { type:"function", name:"claimPass", stateMutability:"nonpayable",
    inputs:[{name:"id",type:"uint256"},{name:"secret",type:"bytes"},{name:"receiver",type:"address"}], outputs:[] },
  { type:"function", name:"refundPass", stateMutability:"nonpayable",
    inputs:[{name:"id",type:"uint256"}], outputs:[] },
  { type:"function", name:"getPass", stateMutability:"view",
    inputs:[{name:"id",type:"uint256"}],
    outputs:[{components:[
      {name:"sender",type:"address"},{name:"token",type:"address"},{name:"amount",type:"uint256"},
      {name:"hashSecret",type:"bytes32"},{name:"expiry",type:"uint64"},
      {name:"claimedBy",type:"address"},{name:"refunded",type:"bool"}
    ], type:"tuple"}] },
] as const;

export const ABI_PAYLINK = [
  { type:"function", name:"createInvoice", inputs:[
    {name:"token",type:"address"},{name:"amount",type:"uint256"},
    {name:"expiry",type:"uint64"},{name:"metadataURI",type:"string"}], stateMutability:"nonpayable", outputs:[{type:"uint256"}] },
  { type:"function", name:"pay", inputs:[
    {name:"id",type:"uint256"},{name:"amount",type:"uint256"},{name:"payer",type:"address"}], stateMutability:"nonpayable", outputs:[] },
  { type:"function", name:"getInvoice", inputs:[{name:"id",type:"uint256"}], stateMutability:"view",
    outputs:[{components:[
      {name:"merchant",type:"address"},{name:"token",type:"address"},
      {name:"amount",type:"uint256"},{name:"expiry",type:"uint64"},
      {name:"metadataURI",type:"string"},{name:"paid",type:"uint256"},{name:"closed",type:"bool"}
    ], type:"tuple"}] },
  // Added close to match LinkPage usage
  { type:"function", name:"close", inputs:[{name:"id",type:"uint256"}], stateMutability:"nonpayable", outputs:[] },
] as const;

export const ABI_ERC20 = [
  { type:"function", name:"decimals", inputs:[], outputs:[{type:"uint8"}], stateMutability:"view" },
  { type:"function", name:"balanceOf", inputs:[{name:"a",type:"address"}], outputs:[{type:"uint256"}], stateMutability:"view" },
  { type:"function", name:"approve", inputs:[{name:"spender",type:"address"},{name:"amount",type:"uint256"}], outputs:[], stateMutability:"nonpayable" },
  { type:"function", name:"mint", inputs:[{name:"amount",type:"uint256"}], outputs:[], stateMutability:"nonpayable" },
  { type:"function", name:"mintTo", inputs:[{name:"to",type:"address"},{name:"amount",type:"uint256"}], outputs:[], stateMutability:"nonpayable" },
  { type:"function", name:"faucet", inputs:[], outputs:[], stateMutability:"nonpayable" },
] as const;
