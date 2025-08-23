"use client";
import { useEffect, useState } from "react";
import { useParams } from "next/navigation";
import { Contract } from "ethers";
import { Button, Segment, Header, Message } from "semantic-ui-react";
import { ADDR } from "@/lib/addr";
import { ABI_PAYLINK, ABI_ERC20 } from "@/lib/abi";
import { ensureConnected } from "@/lib/session";

export default function InvoiceDetail() {
  const { id } = useParams<{id:string}>();
  const [me, setMe] = useState<string>("");
  const [inv, setInv] = useState<any>(null);
  const [decimals, setDecimals] = useState(6);
  const [amount, setAmount] = useState("10000");

  useEffect(()=>{ (async()=>{
    try {
      const c = await ensureConnected();
      setMe(c.address);
      const erc20 = new Contract(ADDR.KRWS, ABI_ERC20, c.web3);
      setDecimals(await erc20.decimals());
      const pay = new Contract(ADDR.PAYLINK, ABI_PAYLINK, c.web3);
      setInv(await pay.getInvoice(id));
    } catch (e:any) { alert(e?.message || "Init failed"); }
  })(); }, [id]);

  if (!inv) return null;
  const isOwner = inv.merchant?.toLowerCase() === me.toLowerCase();
  const expired = Number(inv.expiry) < Math.floor(Date.now()/1000);

  const payInvoice = async () => {
    try {
      const c = await ensureConnected();
      const signer = c.web3.getSigner();
      const pay = new Contract(ADDR.PAYLINK, ABI_PAYLINK, signer);
      const fixed = inv.amount && inv.amount !== "0";
      const units = fixed ? "0" : BigInt(Math.floor(Number(amount) * 10 ** decimals)).toString();
      await pay.pay(id, units, "0x0000000000000000000000000000000000000000");
      alert("Payment sent");
    } catch (e:any) { alert(e?.message || "Payment failed"); }
  };

  const close = async () => {
    try {
      if (!isOwner) return alert("Merchant only");
      const c = await ensureConnected();
      const signer = c.web3.getSigner();
      const pay = new Contract(ADDR.PAYLINK, ABI_PAYLINK, signer);
      await pay.close(id); alert("Invoice closed");
    } catch (e:any) { alert(e?.message || "Close failed"); }
  };

  return (
    <div className="z-card grid gap-4">
      <Header as="h2" color="blue">Invoice #{id}</Header>
      <Segment>
        <div>Merchant: {inv.merchant}</div>
        <div>Amount: {Number(inv.amount)/10**decimals} KRWS (0=variable)</div>
        <div>Expiry: {new Date(Number(inv.expiry)*1000).toLocaleString()}</div>
        <div>Paid: {Number(inv.paid)/10**decimals} KRWS</div>
        <div>Closed: {inv.closed ? "Yes" : "No"}</div>
      </Segment>
      {!inv.closed && (
        <Segment>
          <Header as="h4">결제</Header>
          <div className="flex gap-2 items-center">
            {!inv.amount || inv.amount === "0" ? <input defaultValue={amount} onChange={(e)=>setAmount(e.target.value)} className="ui input" /> : null}
            <Button color="blue" onClick={payInvoice}>Pay</Button>
          </div>
        </Segment>
      )}
      {isOwner && !inv.closed && (
        <Segment>
          <Header as="h4">닫기(취소)</Header>
          <Button color="blue" onClick={close}>Close Invoice</Button>
          {expired ? <Message info content="만료됨(추가 결제는 실패합니다)." /> : null}
        </Segment>
      )}
      {inv.closed && <Message info content="이미 닫힌 인보이스입니다."/>}
    </div>
  );
}
