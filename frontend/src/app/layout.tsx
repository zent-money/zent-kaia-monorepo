"use client";
import "semantic-ui-css/semantic.min.css";
import "./globals.css";
import { Container, Menu } from "semantic-ui-react";
import { WalletButtons } from "@/components/wallet-buttons";

export default function RootLayout({ children }: { children: React.ReactNode }) {
  return (
    <html lang="ko">
      <body>
        <Menu fixed="top" inverted color="blue">
          <Container>
            <Menu.Item header>Zent Dashboard</Menu.Item>
            <Menu.Menu position="right">
              <Menu.Item><WalletButtons /></Menu.Item>
            </Menu.Menu>
          </Container>
        </Menu>
        <Container style={{ marginTop: "5em" }}>{children}</Container>
      </body>
    </html>
  );
}
