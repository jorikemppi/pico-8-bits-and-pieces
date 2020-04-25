-- converts a string containing a hexadecimal number into a decimal number.
-- s and e can be used to define a substring, converts whole string by default.

function hex_to_dec(hexstr, s, e)
 s=s or 1
 e=e or 0
 return tonum("0x"..sub(hexstr, s, s + e))
end