using System;
using System.Diagnostics;
using System.Reflection;
using System.Runtime.InteropServices;
using System.Threading;
using System.Windows.Forms;

[assembly: AssemblyTitle("Logitech MX Ergo Tilt Remapper")]
[assembly: AssemblyDescription("Remaps Logitech MX Ergo horizontal scroll wheel tilt to Back/Forward without Logitech Options")]
[assembly: AssemblyCompany("ldl805")]
[assembly: AssemblyProduct("Logitech-MX-Ergo-Tilt-Windows")]
[assembly: AssemblyCopyright("MIT License")]
[assembly: AssemblyVersion("1.0.0.0")]
[assembly: AssemblyFileVersion("1.0.0.0")]

namespace MxErgoTiltRemap
{
    static class Program
    {
        private const int WH_MOUSE_LL = 14;
        private const int WM_MOUSEHWHEEL = 0x020E;

        private const uint INPUT_MOUSE = 0;
        private const uint MOUSEEVENTF_XDOWN = 0x0080;
        private const uint MOUSEEVENTF_XUP = 0x0100;
        private const uint XBUTTON1 = 0x0001; // Back
        private const uint XBUTTON2 = 0x0002; // Forward

        private static IntPtr _hookID = IntPtr.Zero;
        private static LowLevelMouseProc _proc = HookCallback;
        private static long _lastLeftTick = 0;
        private static long _lastRightTick = 0;
        private static long _cooldownMs = 300; // Prevent rapid fire when holding tilt
        private static bool _invert = false;

        [STAThread]
        static void Main(string[] args)
        {
            foreach (string arg in args)
            {
                if (arg.Equals("--invert", StringComparison.OrdinalIgnoreCase))
                {
                    _invert = true;
                }
                else if (arg.StartsWith("--cooldown=", StringComparison.OrdinalIgnoreCase))
                {
                    long val;
                    if (long.TryParse(arg.Substring("--cooldown=".Length), out val) && val >= 0)
                    {
                        _cooldownMs = val;
                    }
                }
            }

            bool createdNew;
            using (Mutex mutex = new Mutex(true, "Local\\MxErgoTiltRemapMutex", out createdNew))
            {
                if (!createdNew)
                {
                    return; // Already running
                }

                _hookID = SetHook(_proc);
                Application.Run();
                UnhookWindowsHookEx(_hookID);
            }
        }

        private static IntPtr SetHook(LowLevelMouseProc proc)
        {
            using (Process curProcess = Process.GetCurrentProcess())
            using (ProcessModule curModule = curProcess.MainModule)
            {
                return SetWindowsHookEx(WH_MOUSE_LL, proc, GetModuleHandle(curModule.ModuleName), 0);
            }
        }

        private delegate IntPtr LowLevelMouseProc(int nCode, IntPtr wParam, IntPtr lParam);

        private static IntPtr HookCallback(int nCode, IntPtr wParam, IntPtr lParam)
        {
            if (nCode >= 0 && wParam == (IntPtr)WM_MOUSEHWHEEL)
            {
                MSLLHOOKSTRUCT hookStruct = (MSLLHOOKSTRUCT)Marshal.PtrToStructure(lParam, typeof(MSLLHOOKSTRUCT));
                short delta = (short)((hookStruct.mouseData >> 16) & 0xFFFF);
                long now = Environment.TickCount & Int32.MaxValue;

                uint leftButton = _invert ? XBUTTON2 : XBUTTON1;
                uint rightButton = _invert ? XBUTTON1 : XBUTTON2;

                if (delta < 0)
                {
                    // Tilt Left -> Back (by default)
                    if (now - _lastLeftTick >= _cooldownMs || now < _lastLeftTick)
                    {
                        _lastLeftTick = now;
                        ThreadPool.QueueUserWorkItem(_ => SendXButton(leftButton));
                    }
                    return (IntPtr)1; // Swallow horizontal scroll event
                }
                else if (delta > 0)
                {
                    // Tilt Right -> Forward (by default)
                    if (now - _lastRightTick >= _cooldownMs || now < _lastRightTick)
                    {
                        _lastRightTick = now;
                        ThreadPool.QueueUserWorkItem(_ => SendXButton(rightButton));
                    }
                    return (IntPtr)1; // Swallow horizontal scroll event
                }
            }
            return CallNextHookEx(_hookID, nCode, wParam, lParam);
        }

        private static void SendXButton(uint xButton)
        {
            INPUT[] inputs = new INPUT[2];

            inputs[0].type = INPUT_MOUSE;
            inputs[0].u.mi.dwFlags = MOUSEEVENTF_XDOWN;
            inputs[0].u.mi.mouseData = xButton;

            inputs[1].type = INPUT_MOUSE;
            inputs[1].u.mi.dwFlags = MOUSEEVENTF_XUP;
            inputs[1].u.mi.mouseData = xButton;

            SendInput((uint)inputs.Length, inputs, Marshal.SizeOf(typeof(INPUT)));
        }

        [StructLayout(LayoutKind.Sequential)]
        private struct POINT
        {
            public int x;
            public int y;
        }

        [StructLayout(LayoutKind.Sequential)]
        private struct MSLLHOOKSTRUCT
        {
            public POINT pt;
            public uint mouseData;
            public uint flags;
            public uint time;
            public IntPtr dwExtraInfo;
        }

        [StructLayout(LayoutKind.Sequential)]
        private struct INPUT
        {
            public uint type;
            public InputUnion u;
        }

        [StructLayout(LayoutKind.Explicit)]
        private struct InputUnion
        {
            [FieldOffset(0)]
            public MOUSEINPUT mi;
            [FieldOffset(0)]
            public KEYBDINPUT ki;
            [FieldOffset(0)]
            public HARDWAREINPUT hi;
        }

        [StructLayout(LayoutKind.Sequential)]
        private struct MOUSEINPUT
        {
            public int dx;
            public int dy;
            public uint mouseData;
            public uint dwFlags;
            public uint time;
            public IntPtr dwExtraInfo;
        }

        [StructLayout(LayoutKind.Sequential)]
        private struct KEYBDINPUT
        {
            public ushort wVk;
            public ushort wScan;
            public uint dwFlags;
            public uint time;
            public IntPtr dwExtraInfo;
        }

        [StructLayout(LayoutKind.Sequential)]
        private struct HARDWAREINPUT
        {
            public uint uMsg;
            public ushort wParamL;
            public ushort wParamH;
        }

        [DllImport("user32.dll", CharSet = CharSet.Auto, SetLastError = true)]
        private static extern IntPtr SetWindowsHookEx(int idHook, LowLevelMouseProc lpfn, IntPtr hMod, uint dwThreadId);

        [DllImport("user32.dll", CharSet = CharSet.Auto, SetLastError = true)]
        [return: MarshalAs(UnmanagedType.Bool)]
        private static extern bool UnhookWindowsHookEx(IntPtr hhk);

        [DllImport("user32.dll", CharSet = CharSet.Auto, SetLastError = true)]
        private static extern IntPtr CallNextHookEx(IntPtr hhk, int nCode, IntPtr wParam, IntPtr lParam);

        [DllImport("kernel32.dll", CharSet = CharSet.Auto, SetLastError = true)]
        private static extern IntPtr GetModuleHandle(string lpModuleName);

        [DllImport("user32.dll", SetLastError = true)]
        private static extern uint SendInput(uint nInputs, INPUT[] pInputs, int cbSize);
    }
}
