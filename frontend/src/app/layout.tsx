"use client";
import "semantic-ui-css/semantic.min.css";
import "./globals.css";

import Link from "next/link";
import { Container, Menu } from "semantic-ui-react";
import { WalletButtons } from "@/components/wallet-buttons";

export default function RootLayout({ children }: { children: React.ReactNode }) {
  return (
    <html lang="ko">
      <body>
        <Menu fixed="top" inverted color="blue">
          <Container>
            <Menu.Item header as={Link} href="/">Zent</Menu.Item>
            <Menu.Item as={Link} href="/toss">Send via Toss</Menu.Item>
            <Menu.Item as={Link} href="/invoice">Invoice</Menu.Item>
            <Menu.Item as={Link} href="/history">History</Menu.Item>
            <Menu.Item as={Link} href="/my">My</Menu.Item>
            <Menu.Menu position="right">
              <Menu.Item><WalletButtons /></Menu.Item>
            </Menu.Menu>
          </Container>
        </Menu>
        <Container style={{ marginTop: "5.5rem" }}>{children}</Container>
      </body>
    </html>
  );
}
