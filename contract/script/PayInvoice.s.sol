// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "forge-std/Script.sol";
import { ZentPayLink } from "src/ZentPayLink.sol";
import { KRWS } from "src/KRWS.sol";

contract PayInvoice is Script {
    /// @param paylinkAddr ZentPayLink 주소
    /// @param krwsAddr KRWS 토큰 주소 (6 decimals)
    /// @param invoiceId 결제할 인보이스 ID
    /// @param amountUnits 변수 금액 인보이스일 때 쓸 토큰 단위 금액(고정 인보이스면 0 전달)
    /// @param payer 송금자 주소 (msg.sender 사용 시 0x000...0)
    function run(address payable paylinkAddr, address krwsAddr, uint256 invoiceId, uint256 amountUnits, address payer)
        external
    {
        uint256 pk = vm.envUint("DEPLOYER_PRIVATE_KEY");
        address sender = vm.addr(pk);

        vm.startBroadcast(pk);

        // 1) 지갑에 KRWS 확보(필요 시)
        KRWS krws = KRWS(krwsAddr);
        if (amountUnits > 0 && krws.balanceOf(sender) < amountUnits) {
            // 테스트 편의: 부족하면 민트
            krws.mint(amountUnits);
        }

        // 2) PayLink에 KRWS approve
        krws.approve(paylinkAddr, type(uint256).max);

        // 3) 결제 실행 (고정 금액 인보이스: amountUnits=0)
        ZentPayLink(paylinkAddr).pay(invoiceId, amountUnits, payer);

        vm.stopBroadcast();

        console2.log("Paid invoice");
        console2.log("invoiceId:", invoiceId);
        console2.log("amount(units):", amountUnits);
        console2.log("paylink:", paylinkAddr);
    }
}
