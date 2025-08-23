"use client";
import { useState } from "react";
import { Button, Form, Segment, Header, Message } from "semantic-ui-react";
import { Contract, utils } from "ethers";
import { ADDR } from "@/lib/addr";
import { ABI_ESCROW, ABI_ERC20 } from "@/lib/abi";
import { ensureConnected } from "@/lib/session";
import { useRouter } from "next/navigation";

export default function TossPage() {
  const [amount, setAmount] = useState("5000");
  const [decimals, setDecimals] = useState(6);
  const [secret, setSecret] = useState("");
  const [hash, setHash] = useState<string>("");
  const [passId, setPassId] = useState("");
  const router = useRouter();

  const genSecret = () => {
    const s = "toss-" + Math.random().toString(16).slice(2);
    setSecret(s); setHash(utils.keccak256(utils.toUtf8Bytes(s)));
  };

  const readDecimals = async () => {
    try {
      const c = await ensureConnected();
      const erc20 = new Contract(ADDR.KRWS, ABI_ERC20, c.web3);
      setDecimals(await erc20.decimals());
    } catch (e:any) { alert(e?.message || "Failed to read decimals"); }
  };

  const approve = async () => {
    try {
      const c = await ensureConnected();
      const signer = c.web3.getSigner();
      const erc20 = new Contract(ADDR.KRWS, ABI_ERC20, signer);
      const units = BigInt(Math.floor(Number(amount) * 10 ** decimals));
      await erc20.approve(ADDR.ESCROW, units.toString());
      alert("Approve OK");
    } catch (e:any) { alert(e?.message || "Approve failed"); }
  };

  const createPass = async () => {
    try {
      if (!hash) return alert("Secret/Hash 먼저 생성");
      const c = await ensureConnected();
      const signer = c.web3.getSigner();
      const escrow = new Contract(ADDR.ESCROW, ABI_ESCROW, signer);
      const units = BigInt(Math.floor(Number(amount) * 10 ** decimals));
      const expiry = Math.floor(Date.now()/1000 + 24*3600);
      const tx = await escrow.createPass(ADDR.KRWS, units.toString(), hash, expiry);
      await tx.wait();
      localStorage.setItem(`zent:pass:secret:${c.address}`, secret);
      localStorage.setItem(`zent:lastActor`, c.address);
      alert("Pass created. (이벤트 로그에서 ID 확인 후 경로로 접근 /toss/<id>)");
    } catch (e:any) { alert(e?.message || "Create failed"); }
  };

  const go = () => { if (!passId) return alert("Pass ID 입력"); router.push(`/toss/${passId}`); };

  return (
    <div className="z-card grid gap-4">
      <Header as="h2" color="blue">Send via Toss</Header>
      <Segment>
        <Header as="h4">보내기</Header>
        <Form>
          <Form.Group widths="equal">
            <Form.Input label="Amount (KRWS)" value={amount} onChange={(_,d)=>setAmount(String(d.value))}/>
            <Form.Input label="Decimals" value={decimals} readOnly action={{content:"read", color:"blue", onClick:readDecimals}} />
          </Form.Group>
          <Button color="blue" onClick={genSecret}>Generate Secret/Hash</Button>
          <Button color="blue" onClick={approve}>Approve</Button>
          <Button color="blue" onClick={createPass}>Create Toss</Button>
        </Form>
        {secret && <Message info content={`secret: ${secret}`} />}
        {hash && <Message content={`hash: ${hash}`} />}
      </Segment>

      <Segment>
        <Header as="h4">받기 (Path/ID로 진입)</Header>
        <Form onSubmit={go}>
          <Form.Input label="Pass ID" value={passId} onChange={(_,d)=>setPassId(String(d.value))}/>
          <Button color="blue" type="submit">Go to /toss/[id]</Button>
        </Form>
      </Segment>
    </div>
  );
}
