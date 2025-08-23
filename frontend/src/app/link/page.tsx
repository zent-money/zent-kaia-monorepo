"use client";
import { useEffect, useState } from "react";
import { Button, Form, Segment, Header, Message } from "semantic-ui-react";
import { Contract } from "ethers";
import { connectKaiaWallet, Connected } from "@/lib/kaia";
import { ADDR } from "@/lib/addr";
import { ABI_PAYLINK, ABI_ERC20 } from "@/lib/abi";

export default function LinkPage() {
  const [conn, setConn] = useState<Connected|null>(null);
  const [amount, setAmount] = useState("10000");
  const [decimals, setDecimals] = useState(6);
  const [invoiceId, setInvoiceId] = useState("");

  const ensure = async()=> conn ?? (await connectKaiaWallet());

  useEffect(()=>{ (async()=>{
    try { const c = await ensure(); setConn(c);
      const erc20 = new Contract(ADDR.KRWS, ABI_ERC20, c.web3);
      setDecimals(await erc20.decimals());
    } catch {}
  })(); // eslint-disable-next-line react-hooks/exhaustive-deps
  },[]);

  const faucet = async () => {
    const c = await ensure(); setConn(c);
    const erc20 = new Contract(ADDR.KRWS, ABI_ERC20, c.web3.getSigner());
    await erc20.faucet(); alert("KRWS faucet (100,000)");
  };

  const approve = async () => {
    const c = await ensure(); setConn(c);
    const erc20 = new Contract(ADDR.KRWS, ABI_ERC20, c.web3.getSigner());
    const units = BigInt(Math.floor(Number(amount) * 10 ** decimals));
    await erc20.approve(ADDR.PAYLINK, units.toString()); alert("Approve OK");
  };

  const createInvoice = async () => {
    const c = await ensure(); setConn(c);
    const pay = new Contract(ADDR.PAYLINK, ABI_PAYLINK, c.web3.getSigner());
    const units = BigInt(Math.floor(Number(amount) * 10 ** decimals));
    const expiry = Math.floor(Date.now()/1000 + 24*3600);
    await pay.createInvoice(ADDR.KRWS, units.toString(), expiry, "demo-metadata");
    alert("Invoice created (ID는 이벤트 로그에서 확인)");
  };

  const payInvoice = async () => {
    const c = await ensure(); setConn(c);
    const pay = new Contract(ADDR.PAYLINK, ABI_PAYLINK, c.web3.getSigner());
    const units = BigInt(Math.floor(Number(amount) * 10 ** decimals)); // variable invoice일 때
    await pay.pay(invoiceId, units.toString(), "0x0000000000000000000000000000000000000000");
    alert("Payment sent");
  };

  const close = async () => {
    const c = await ensure(); setConn(c);
    const pay = new Contract(ADDR.PAYLINK, ABI_PAYLINK, c.web3.getSigner());
    await pay.close(invoiceId); alert("Invoice closed");
  };

  return (
    <div className="grid gap-4">
      <Header as="h2" color="blue">Zent Link — 인보이스</Header>
      {null}
      <Segment>
        <Form>
          <Form.Group widths="equal">
            <Form.Input label="Amount (KRWS)" value={amount} onChange={(_,d)=>setAmount(String(d.value))}/>
            <Form.Input label="Invoice ID" value={invoiceId} onChange={(_,d)=>setInvoiceId(String(d.value))}/>
          </Form.Group>
          <Button color="blue" onClick={faucet}>Get KRWS (faucet)</Button>
          <Button color="blue" onClick={approve}>Approve</Button>
          <Button color="blue" onClick={createInvoice}>Create Invoice</Button>
          <Button color="blue" onClick={payInvoice}>Pay</Button>
          <Button color="blue" onClick={close}>Close</Button>
        </Form>
      </Segment>
      <Message info>가변 인보이스는 Pay 시 Amount 사용, 고정 인보이스는 Amount=0 전달.</Message>
    </div>
  );
}
