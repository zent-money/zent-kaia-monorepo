"use client";
import { useState } from "react";
import { Button, Form, Segment, Message, Header } from "semantic-ui-react";
import { Contract, utils } from "ethers";
import { connectKaiaWallet, Connected } from "@/lib/kaia";
import { ADDR } from "@/lib/addr";
import { ABI_ESCROW, ABI_ERC20 } from "@/lib/abi";

export default function PassPage() {
  const [conn, setConn] = useState<Connected|null>(null);
  const [amount, setAmount] = useState("5000");
  const [decimals, setDecimals] = useState(6);
  const [secret, setSecret] = useState("");
  const [hash, setHash] = useState<string>("");

  // If you want to enforce header connection only, throw when null.
  const ensure = async()=> conn ?? (await connectKaiaWallet());

  const genSecret = () => {
    const s = "sample-" + Math.random().toString(16).slice(2);
    setSecret(s);
    setHash(utils.keccak256(utils.toUtf8Bytes(s)));
  };

  const readDecimals = async () => {
    const c = await ensure(); setConn(c);
    const erc20 = new Contract(ADDR.KRWS, ABI_ERC20, c.web3);
    const d: number = await erc20.decimals(); setDecimals(d);
  };

  const approve = async () => {
    const c = await ensure(); setConn(c);
    const signer = c.web3.getSigner();
    const erc20 = new Contract(ADDR.KRWS, ABI_ERC20, signer);
    const units = BigInt(Math.floor(Number(amount) * 10 ** decimals));
    await erc20.approve(ADDR.ESCROW, units.toString());
    alert("Approve OK");
  };

  const createPass = async () => {
    if (!hash) return alert("Secret/Hash 먼저 생성");
    const c = await ensure(); setConn(c);
    const signer = c.web3.getSigner();
    const escrow = new Contract(ADDR.ESCROW, ABI_ESCROW, signer);
    const units = BigInt(Math.floor(Number(amount) * 10 ** decimals));
    const expiry = Math.floor(Date.now()/1000 + 24*3600);
    await escrow.createPass(ADDR.KRWS, units.toString(), hash, expiry);
    alert("Pass created");
  };

  const claim = async (id: string, recv?: string) => {
    if (!secret) return alert("Secret 필요");
    const c = await ensure(); setConn(c);
    const signer = c.web3.getSigner();
    const escrow = new Contract(ADDR.ESCROW, ABI_ESCROW, signer);
    const r = recv && recv.length>0 ? recv : "0x0000000000000000000000000000000000000000";
    await escrow.claimPass(id, utils.toUtf8Bytes(secret), r);
    alert("Claim sent");
  };

  const refund = async (id: string) => {
    const c = await ensure(); setConn(c);
    const signer = c.web3.getSigner();
    const escrow = new Contract(ADDR.ESCROW, ABI_ESCROW, signer);
    await escrow.refundPass(id);
    alert("Refund tx sent");
  };

  return (
    <div className="grid gap-4">
      <Header as="h2" color="blue">Zent Pass — 링크 기반 송금</Header>
      {null}
      <Segment>
        <Form>
          <Form.Group widths="equal">
            <Form.Input label="Amount (KRWS)" value={amount} onChange={(_,d)=>setAmount(String(d.value))}/>
            <Form.Input label="Decimals" value={decimals} readOnly action={{content:"read", color:"blue", onClick:readDecimals}} />
          </Form.Group>
          <Button color="blue" onClick={genSecret}>Generate Secret/Hash</Button>
          <Button color="blue" onClick={approve}>Approve</Button>
          <Button color="blue" onClick={createPass}>Create Pass</Button>
        </Form>
        {secret && <Message info content={`secret: ${secret}`} />}
        {hash && <Message content={`hash: ${hash}`} />}
      </Segment>
      <Segment>
        <Header as="h4">Claim / Refund</Header>
        <ClaimRefundForm onClaim={claim} onRefund={refund}/>
      </Segment>
    </div>
  );
}

function ClaimRefundForm({ onClaim, onRefund }:{ onClaim:(id:string,recv?:string)=>void; onRefund:(id:string)=>void }) {
  const [id, setId] = useState(""); const [recv, setRecv] = useState("");
  return (
    <Form onSubmit={()=>onClaim(id, recv)}>
      <Form.Group widths="equal">
        <Form.Input label="Pass ID" value={id} onChange={(_,d)=>setId(String(d.value))}/>
        <Form.Input label="Receiver(optional)" value={recv} onChange={(_,d)=>setRecv(String(d.value))}/>
      </Form.Group>
      <Button color="blue" type="submit">Claim</Button>
      <Button color="blue" type="button" onClick={()=>onRefund(id)}>Refund</Button>
    </Form>
  );
}
