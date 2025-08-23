"use client";
import { useState, useEffect } from "react";
import { Button, Form, Segment, Header, Message } from "semantic-ui-react";
import { Contract } from "ethers";
import { ADDR } from "@/lib/addr";
import { ABI_PAYLINK, ABI_ERC20 } from "@/lib/abi";
import { ensureConnected } from "@/lib/session";
import { useRouter } from "next/navigation";

export default function InvoicePage() {
  const [amount, setAmount] = useState("10000");
  const [decimals, setDecimals] = useState(6);
  const [invoiceId, setInvoiceId] = useState("");
  const router = useRouter();

  useEffect(()=>{ (async()=>{
    try { const c = await ensureConnected();
      const erc20 = new Contract(ADDR.KRWS, ABI_ERC20, c.web3);
      setDecimals(await erc20.decimals());
    } catch{}
  })(); }, []);

  const faucet = async () => {
    try {
      const c = await ensureConnected();
      const erc20 = new Contract(ADDR.KRWS, ABI_ERC20, c.web3.getSigner());
      await erc20.faucet(); alert("KRWS faucet");
    } catch (e:any) { alert(e?.message || "Faucet failed"); }
  };

  const approve = async () => {
    try {
      const c = await ensureConnected();
      const erc20 = new Contract(ADDR.KRWS, ABI_ERC20, c.web3.getSigner());
      const units = BigInt(Math.floor(Number(amount) * 10 ** decimals));
      await erc20.approve(ADDR.PAYLINK, units.toString()); alert("Approve OK");
    } catch (e:any) { alert(e?.message || "Approve failed"); }
  };

  const createInvoice = async () => {
    try {
      const c = await ensureConnected();
      const pay = new Contract(ADDR.PAYLINK, ABI_PAYLINK, c.web3.getSigner());
      const units = BigInt(Math.floor(Number(amount) * 10 ** decimals));
      const expiry = Math.floor(Date.now()/1000 + 24*3600);
      const tx = await pay.createInvoice(ADDR.KRWS, units.toString(), expiry, "demo");
      await tx.wait();
      localStorage.setItem(`zent:lastActor`, c.address);
      alert("Invoice created. (이벤트 로그에서 ID 확인 후 /invoice/<id> 로 접근)");
    } catch (e:any) { alert(e?.message || "Create failed"); }
  };

  const go = () => { if (!invoiceId) return alert("Invoice ID 입력"); router.push(`/invoice/${invoiceId}`); };

  return (
    <div className="z-card grid gap-4">
      <Header as="h2" color="blue">Invoice</Header>
      <Segment>
        <Header as="h4">인보이스 생성</Header>
        <Form>
          <Form.Group widths="equal">
            <Form.Input label="Amount (KRWS)" value={amount} onChange={(_,d)=>setAmount(String(d.value))}/>
            <Form.Input label="Decimals" value={decimals} readOnly />
          </Form.Group>
          <Button color="blue" onClick={faucet}>Get KRWS (faucet)</Button>
          <Button color="blue" onClick={approve}>Approve</Button>
          <Button color="blue" onClick={createInvoice}>Create Invoice</Button>
        </Form>
      </Segment>

      <Segment>
        <Header as="h4">결제 이동 (Path/ID)</Header>
        <Form onSubmit={go}>
          <Form.Input label="Invoice ID" value={invoiceId} onChange={(_,d)=>setInvoiceId(String(d.value))}/>
          <Button color="blue" type="submit">Go to /invoice/[id]</Button>
        </Form>
      </Segment>
      <Message info>고정 금액 인보이스는 Pay 호출 시 amount=0로 처리됩니다(컨트랙트 내부 로직 기준).</Message>
    </div>
  );
}
