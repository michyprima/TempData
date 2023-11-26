using OpenHardwareMonitor.Hardware;
using System;
using System.Collections.Generic;
using System.IO.Ports;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using Microsoft.WindowsAPICodePack.ApplicationServices;
using System.Threading;
using System.Windows.Forms;

namespace TempData
{
    class Program
    {
        static bool screenStatus;
        static Mutex mutex = new Mutex(false, "TempData Serial Adapter");


        static int shortcutCommand = -1;
        static void HotKeyManager_HotKeyPressed(object sender, HotKeyEventArgs e)
        {
            if(e.Modifiers > 0)
            {
                shortcutCommand = 1;
            }
            else
            {
                shortcutCommand = 0;
            }
        }

        [STAThread]
        static void Main(string[] args)
        {
            if (!mutex.WaitOne(TimeSpan.Zero, false))
            {
                return;
            }

            HotKeyManager.RegisterHotKey(Keys.Pause, 0);
            HotKeyManager.RegisterHotKey(Keys.Pause, KeyModifiers.Shift);
            HotKeyManager.HotKeyPressed += new EventHandler<HotKeyEventArgs>(HotKeyManager_HotKeyPressed);

            screenStatus = PowerManager.IsMonitorOn;
            PowerManager.IsMonitorOnChanged += PowerManager_IsMonitorOnChanged;
            var computer = new Computer()
            {
                MainboardEnabled = false,
                CPUEnabled = true,
                RAMEnabled = true,
                GPUEnabled = true,
                FanControllerEnabled = false,
                HDDEnabled = false,
            };
            computer.Open();

            ushort [] data = new ushort[8];
            byte[] buffer = new byte[32];

            while (true)
            {
                SerialPort _serialPort = new SerialPort();
                _serialPort.PortName = args[0];
                _serialPort.DtrEnable = false;
                _serialPort.RtsEnable = false;
                _serialPort.Handshake = Handshake.None;
                _serialPort.BaudRate = 921600;
                int lastSentMinute = -1;
                
                try
                {
                    _serialPort.Open();
                }
                catch(Exception)
                {
                    Thread.Sleep(1000);
                    continue;
                }
                Thread.Sleep(1500);

                while (true)
                {
                    if (screenStatus)
                    {
                        float lastClock = 0;
                        for (int i = 0; i < computer.Hardware.Length; i++)
                        {
                            IHardware hw = computer.Hardware[i];
                            hw.Update();
                            for (int j = 0; j < hw.Sensors.Length; j++)
                            {
                                ISensor s = hw.Sensors[j];

                                if (s.IsDefaultHidden)
                                    continue;

                                switch (hw.HardwareType)
                                {
                                    case HardwareType.CPU:
                                        switch (s.SensorType)
                                        {
                                            case SensorType.Clock:
                                                if (s.Value > lastClock)
                                                {
                                                    lastClock = s.Value.GetValueOrDefault(0);
                                                    data[0] = (ushort)Math.Round(lastClock);
                                                }
                                                break;
                                            case SensorType.Temperature:
                                                if (s.Name.Equals("CPU Package"))
                                                    data[1] = (ushort)Math.Round((double)s.Value);
                                                break;
                                            case SensorType.Load:
                                                if (s.Name.Contains("Total"))
                                                    data[2] = (ushort)Math.Round(s.Value.GetValueOrDefault(0));
                                                break;
                                        }
                                        break;
                                    case HardwareType.RAM:
                                        if (s.SensorType == SensorType.Load)
                                            data[3] = (ushort)Math.Round(s.Value.GetValueOrDefault(0));
                                        break;
                                    case HardwareType.GpuNvidia:
                                        switch (s.SensorType)
                                        {
                                            case SensorType.Clock:
                                                if (s.Name.Equals("GPU Core"))
                                                {
                                                    double v = Math.Round(s.Value.GetValueOrDefault(0));
                                                    if(v > 0)
                                                        data[4] = (ushort)v;
                                                }
                                                break;
                                            case SensorType.Temperature:
                                                if (s.Name.Equals("GPU Core"))
                                                    data[5] = (ushort)Math.Round(s.Value.GetValueOrDefault(0));
                                                break;
                                            case SensorType.Load:
                                                if (s.Name.Equals("GPU Core"))
                                                    data[6] = (ushort)Math.Round(s.Value.GetValueOrDefault(0));
                                                else if (s.Name.Equals("GPU Memory"))
                                                    data[7] = (ushort)Math.Round(s.Value.GetValueOrDefault(0));
                                                break;
                                        }
                                        break;
                                }
                            }
                        }
                        try
                        {


                            buffer[0] = 0x03;
                            for (int i = 0; i < 8; i++)
                            {
                                buffer[1 + (i * 2)] = (byte)(data[i] & 0xff);
                                buffer[2 + (i * 2)] = (byte)(data[i] >> 8);
                            }
                            _serialPort.DiscardInBuffer();
                            _serialPort.Write(buffer, 0, 17);
                            int res = _serialPort.ReadByte();

                            var now = DateTime.Now;
                            if (lastSentMinute != now.Minute)
                            {
                                buffer[0] = 0x02;
                                buffer[1] = (byte)now.Hour;
                                buffer[2] = (byte)now.Minute;
                                buffer[3] = (byte)now.Day;
                                buffer[4] = (byte)now.Month;
                                buffer[5] = (byte)(now.Year - 2000);
                                _serialPort.DiscardInBuffer();
                                _serialPort.Write(buffer, 0, 6);
                                res = _serialPort.ReadByte();
                                if(res == 0)
                                {
                                    lastSentMinute = now.Minute;
                                }
                            }
                        }
                        catch (Exception ex)
                        {
                            break;
                        }
                    }
                    else
                    {
                        try
                        {
                            _serialPort.DiscardInBuffer();
                            buffer[0] = 0x04;
                            _serialPort.Write(buffer, 0, 1);
                            _serialPort.ReadByte();
                        }
                        catch (Exception)
                        {
                        }
                        while(!screenStatus)
                        {
                            Application.DoEvents();
                            Thread.Sleep(1000);
                        }
                    }
                    Application.DoEvents();
                    for (int i = 0; i < 10; i++)
                    {
                        if(shortcutCommand > -1)
                        {
                            if (shortcutCommand == 0)
                            {
                                buffer[0] = 0x05;
                            }
                            else
                            {
                                buffer[0] = 0x06;
                            }
                            _serialPort.DiscardInBuffer();
                            _serialPort.Write(buffer, 0, 1);
                            _serialPort.ReadByte();
                            shortcutCommand = -1;
                        }
                        Thread.Sleep(100);
                    }
                }
            }
        }

        private static void PowerManager_IsMonitorOnChanged(object sender, EventArgs e)
        {
            screenStatus = PowerManager.IsMonitorOn;
        }
    }
}
