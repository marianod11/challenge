// SPDX-License-Identifier: MIT

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol

pragma solidity ^0.8.0;

interface IERC20 {
    /**
     * @dev Devuelve la cantidad de tokens existentes.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Devuelve la cantidad de tokens que posee la `cuenta`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Mueve los tokens de "cantidad" de la cuenta de la persona que llama al "destinatario".
     *
     * Devuelve un valor booleano que indica si la operación se realizó correctamente.
     *
     * Emite un evento {Transfer}.
     */
    function transfer(
        address recipient,
        uint256 amount
    ) external returns (bool);

    /**
     * @dev Devuelve el número restante de tokens que el `gastador` será
     * permitido gastar en nombre del `propietario` a través de {transferFrom}. Este es
     * cero por defecto.
     *
     * Este valor cambia cuando se llama a {aprobar} o {transferFrom}.
     */
    function allowance(
        address owner,
        address spender
    ) external view returns (uint256);

    /**
     * @dev Establece `amount` como la asignación de` gastador` sobre los tokens de la persona que llama.
     *
     * Devuelve un valor booleano que indica si la operación se realizó correctamente.
     *
     * IMPORTANTE: tenga en cuenta que cambiar una asignación con este método conlleva el riesgo
     * que alguien pueda usar tanto la asignación antigua como la nueva por desafortunado
     * pedido de transacciones. Una posible solución para mitigar esta carrera
     * La condición es primero reducir la asignación del gastador a 0 y establecer la
     * valor deseado después:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emite un evento de {Aprobación}.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Mueve los tokens de `cantidad` de` remitente` a `destinatario` usando el
     * mecanismo de subsidio. La `cantidad` se deduce de la cantidad de la persona que llama.
     * prestación.
     *
     * Devuelve un valor booleano que indica si la operación se realizó correctamente.
     *
     * Emite un evento {Transfer}.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    /**
     * @dev Emitido cuando los tokens `value` se mueven de una cuenta (` from`) a
     * otro (`a`).
     *
     * Tenga en cuenta que el "valor" puede ser cero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitido cuando la asignación de un "gastador" para un "propietario" es establecida por
     * una llamada a {aprobar}. `value` es la nueva asignación.
     */
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}
