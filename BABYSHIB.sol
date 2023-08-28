// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

library SafeMath {
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) { unchecked { uint256 c = a + b; if (c < a) return (false, 0); return (true, c); } }
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) { unchecked { if (b > a) return (false, 0); return (true, a - b); } }
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) { unchecked { if (a == 0) return (true, 0); uint256 c = a * b; if (c / a != b) return (false, 0); return (true, c); } }
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) { unchecked { if (b == 0) return (false, 0); return (true, a / b); } }
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) { unchecked { if (b == 0) return (false, 0); return (true, a % b); } }
    function add(uint256 a, uint256 b) internal pure returns (uint256) { return a + b; }
    function sub(uint256 a, uint256 b) internal pure returns (uint256) { return a - b; }
    function mul(uint256 a, uint256 b) internal pure returns (uint256) { return a * b; }
    function div(uint256 a, uint256 b) internal pure returns (uint256) { return a / b; }
    function mod(uint256 a, uint256 b) internal pure returns (uint256) { return a % b; }
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) { unchecked { require(b <= a, errorMessage); return a - b; } }
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) { unchecked { require(b > 0, errorMessage); return a / b; } }
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) { unchecked { require(b > 0, errorMessage); return a % b; } }
}

library TransferHelper {
    function safeApprove(address token, address to, uint256 value) internal { (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x095ea7b3, to, value)); require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper::safeApprove: approve failed'); }
    function safeTransfer(address token, address to, uint256 value) internal { (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0xa9059cbb, to, value)); require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper::safeTransfer: transfer failed'); }
    function safeTransferFrom(address token, address from, address to, uint256 value) internal { (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x23b872dd, from, to, value)); require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper::transferFrom: transferFrom failed'); }
    function safeTransferETH(address to, uint256 value) internal { (bool success, ) = to.call{value: value}(new bytes(0)); require(success, 'TransferHelper::safeTransferETH: ETH transfer failed'); }
}

interface IERC20 {
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address to, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
}

interface IWETH is IERC20 {
    function deposit() external payable;
    function transfer(address to, uint256 value) external returns (bool);
    function withdraw(uint256) external;
}

interface IFactory {
    function createPair(address tokenA, address tokenB) external returns (address pair);
}

interface IRouter {
    function factory() external view returns (address);
    function WETH() external view returns (address);
    function swapExactTokensForETH(uint256 amountIn, uint256 amountOutMin, address[] calldata path, address to, uint256 deadline) external;
    function swapExactTokensForTokens(uint256 amountIn, uint256 amountOutMin, address[] calldata path, address to, uint256 deadline) external;
}

contract TokenBus {
    address public deployer;
    address public token;

    constructor (address token_, address deployer_) {
        deployer = deployer_;
        token = token_;
        IERC20(token_).approve(msg.sender, uint(~uint256(0)));
    }

    function sweep() external {
        require(msg.sender == deployer, "Only deployer can sweep");
        IERC20(token).transfer(deployer, IERC20(token).balanceOf(address(this)));
    }
}

abstract contract Context {
    function _msgSender() internal view virtual returns (address) { return msg.sender; }
    function _msgData() internal view virtual returns (bytes calldata) { return msg.data; }
}

abstract contract Ownable is Context {
    address private _owner;
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    constructor() { _transferOwnership(_msgSender()); }
    modifier onlyOwner() { _checkOwner(); _; }
    function owner() public view virtual returns (address) { return _owner; }
    function _checkOwner() internal view virtual { require(owner() == _msgSender(), "Ownable: caller is not the owner"); }
    function renounceOwnership() public virtual onlyOwner { _transferOwnership(address(0)); }
    function transferOwnership(address newOwner) public virtual onlyOwner { require(newOwner != address(0), "Ownable: new owner is the zero address"); _transferOwnership(newOwner); }
    function _transferOwnership(address newOwner) internal virtual { address oldOwner = _owner; _owner = newOwner; emit OwnershipTransferred(oldOwner, newOwner); }
}

abstract contract ERC20 is Context, IERC20 {
    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;
    uint256 private _totalSupply;
    uint8 private _decimals;
    string private _name;
    string private _symbol;

    constructor(string memory name_, string memory symbol_, uint8 decimals_) { _name = name_; _symbol = symbol_; _decimals = decimals_; }
    function name() public view virtual override returns (string memory) { return _name; }
    function symbol() public view virtual override returns (string memory) { return _symbol; }
    function decimals() public view virtual override returns (uint8) { return _decimals; }
    function totalSupply() public view virtual override returns (uint256) { return _totalSupply; }
    function balanceOf(address account) public view virtual override returns (uint256) { return _balances[account]; }
    function transfer(address to, uint256 amount) public virtual override returns (bool) { address owner = _msgSender(); _transfer(owner, to, amount); return true; }
    function allowance(address owner, address spender) public view virtual override returns (uint256) { return _allowances[owner][spender]; }
    function approve(address spender, uint256 amount) public virtual override returns (bool) { address owner = _msgSender(); _approve(owner, spender, amount); return true; }
    function transferFrom(address from, address to, uint256 amount) public virtual override returns (bool) { address spender = _msgSender(); _spendAllowance(from, spender, amount); _transfer(from, to, amount); return true; }
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) { address owner = _msgSender(); _approve(owner, spender, allowance(owner, spender) + addedValue); return true; }
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        address owner = _msgSender();
        uint256 currentAllowance = allowance(owner, spender);
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked { _approve(owner, spender, currentAllowance - subtractedValue); }
        return true;
    }
    function _transfer(address from, address to, uint256 amount) internal virtual {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        _beforeTokenTransfer(from, to, amount);
        uint256 fromBalance = _balances[from];
        require(fromBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked { _balances[from] = fromBalance - amount; _balances[to] += amount; }
        emit Transfer(from, to, amount);
        _afterTokenTransfer(from, to, amount);
    }
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");
        _beforeTokenTransfer(address(0), account, amount);
        _totalSupply += amount;
        unchecked { _balances[account] += amount; }
        emit Transfer(address(0), account, amount);
        _afterTokenTransfer(address(0), account, amount);
    }
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");
        _beforeTokenTransfer(account, address(0), amount);
        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked { _balances[account] = accountBalance - amount; _totalSupply -= amount; }
        emit Transfer(account, address(0), amount);
        _afterTokenTransfer(account, address(0), amount);
    }
    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }
    function _spendAllowance(address owner, address spender, uint256 amount) internal virtual {
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
            require(currentAllowance >= amount, "ERC20: insufficient allowance");
            unchecked { _approve(owner, spender, currentAllowance - amount); }
        }
    }
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual {}
    function _afterTokenTransfer(address from, address to, uint256 amount) internal virtual {}
}

contract BABYSHIB is ERC20, Ownable {
    using SafeMath for uint256;

    address public wbone;
    address public mainpair;
    address public routerAddr = 0xDdcb1Fb0dC2Bc5D750F1351fB6f471e1CaF2D10b; // ballswap
    address public marketingAddr = 0x8118e74B5F0696C811D528CA8821Bc2EE0b06Db6;
    bool public launched;

    uint256 public buyfee = 3;
    uint256 public sellfee = 15;
    uint256 public constant distributeAmount = 10 * 10**18; // 10BONE

    bool    private _swapping;
    uint256 private _swapAmount;
    uint256 private constant _totalSupply = 10000 * 10000 * 10000 * (10**18);

    address[] public holders;
    uint256 private _idx;

    TokenBus public tokenDistributor;

    mapping(address => bool) private _isHolder;
    mapping(address => bool) private _isExcludedFromFees;

    event Launched(uint256 blockNumber);

    constructor(address to) ERC20("BABYSHIB", "BABYSHIB", 18) {
        wbone = IRouter(routerAddr).WETH();
        mainpair = IFactory(IRouter(routerAddr).factory()).createPair(wbone, address(this));

        tokenDistributor = new TokenBus(wbone, msg.sender);

        _swapAmount = _totalSupply.div(1000);

        excludeFromFees(address(this), true);
        excludeFromFees(marketingAddr, true);
        excludeFromFees(msg.sender, true);
        excludeFromFees(to, true);

        _mint(to, _totalSupply);
        _approve(address(this), routerAddr, ~uint256(0));
    }

    receive() external payable {}

    function launch() external onlyOwner {
        require(!launched, "Already launched");
        launched = true;
        emit Launched(block.number);
    }

    function setFees(uint256 _buyfee, uint256 _sellfee) external onlyOwner {
        require(_buyfee <= buyfee && _sellfee <= sellfee, "Can't increase fees");
        buyfee = _buyfee;
        sellfee = _sellfee;
    }

    function excludeFromFees(address account, bool excluded) public onlyOwner { _isExcludedFromFees[account] = excluded; }

    function _transfer(address from, address to, uint256 amount) internal override {
        require(from != address(0));
        require(to != address(0));
        require(amount != 0);
        require(launched || _isExcludedFromFees[from] || _isExcludedFromFees[to]);

        if (!_isExcludedFromFees[from] && !_isExcludedFromFees[to]) {
            if (to == mainpair && !_swapping && balanceOf(address(this)) >= _swapAmount) {
                _swapping = true;
                _swapWBone(balanceOf(address(this)).div(3), address(tokenDistributor));
                _swapBone(balanceOf(address(this)), marketingAddr);
                _swapping = false;
            }

            if (!_swapping) {
                uint256 fee = from == mainpair ? buyfee : to == mainpair ? sellfee : 0;
                uint256 feeAmount = amount.mul(fee).div(100);
                if (feeAmount > 0) { amount = amount.sub(feeAmount); super._transfer(from, address(this), feeAmount); }
                if (amount > 1) amount = amount.sub(1);
            }
        }

        super._transfer(from, to, amount);

        if (!_swapping) {
            _addHolder(to);
            _processReward(500000);
        }
    }

    function _swapWBone(uint256 amount, address to) internal {
        if (amount == 0) return;
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = wbone;
        IRouter(routerAddr).swapExactTokensForTokens(amount, 0, path, to, block.timestamp);
    }

    function _swapBone(uint256 amount, address to) internal {
        if (amount == 0) return;
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = wbone;
        IRouter(routerAddr).swapExactTokensForETH(amount, 0, path, to, block.timestamp);
    }

    function _addHolder(address adr) internal {
        if (adr == mainpair) return;
        if (_isExcludedFromFees[adr]) return;
        if (_isHolder[adr]) return;
        if (balanceOf(adr) < _totalSupply.div(10000)) return;

        holders.push(adr);
        _isHolder[adr] = true;
    }

    function _processReward(uint256 gas) internal {
        uint256 wboneBalance = IERC20(wbone).balanceOf(address(tokenDistributor));
        if (wboneBalance < distributeAmount) return;

        TransferHelper.safeTransferFrom(wbone, address(tokenDistributor), address(this), wboneBalance);
        IWETH(wbone).withdraw(wboneBalance);

        uint256 gasUsed = 0;
        uint256 iterations = 0;
        uint256 gasLeft = gasleft();

        address holder;
        uint256 holderBalance;
        uint256 amount;

        uint256 holderCount = holders.length;

        while (gasUsed < gas && iterations < holderCount) {
            if (_idx >= holderCount) _idx = 0;
            holder = holders[_idx];
            holderBalance = balanceOf(holder);

            if (holderBalance >= _totalSupply.div(10000)) {
                amount = wboneBalance.mul(holderBalance).div(_totalSupply);
                TransferHelper.safeTransferETH(holder, amount);
            }
            gasUsed = gasUsed + (gasLeft - gasleft());
            gasLeft = gasleft();
            _idx++;
            iterations++;
        }
    }
}
