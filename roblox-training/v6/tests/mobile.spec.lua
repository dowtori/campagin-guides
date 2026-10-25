local M=require('./NativeUiMock');M.width=300
local H=require('./ClientHarness');H.input.TouchEnabled=true
require('./client.spec')
print('PASS: native touch-mode callbacks exercised; text layout still requires a real device')
