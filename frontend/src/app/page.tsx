"use client";
import Link from "next/link";
import { Card } from "semantic-ui-react";

export default function Home() {
  const items = [
    { header: "Zent Pass", description: "링크 기반 송금 (ERC20)", href: "/pass" },
    { header: "Zent Link", description: "결제받는 링크 (ERC20)", href: "/link" },
  ];
  return (
    <>
      <h1 className="ui header">Welcome to Zent</h1>
      <Card.Group itemsPerRow={2}>
        {items.map(i => <Card key={i.header} header={i.header} description={i.description} as={Link} href={i.href} color="blue" />)}
      </Card.Group>
    </>
  );
}
