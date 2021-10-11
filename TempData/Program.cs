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

        [STAThread]
        static void Main(string[] args)
        {
            if (!mutex.WaitOne(TimeSpan.Zero, false))
            {
                return;
            }

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

            string[] data = new string[8];

            while (true)
            {
                SerialPort _serialPort = new SerialPort();
                _serialPort.PortName = args[0];
                _serialPort.BaudRate = 115200;
                _serialPort.NewLine = "\r\n";
                
                try
                {
                    _serialPort.Open();
                    _serialPort.Write(_serialPort.NewLine);
                }
                catch(Exception)
                {
                    Thread.Sleep(1000);
                    continue;
                }
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
                                                    data[0] = (Math.Round(lastClock)).ToString();
                                                }
                                                break;
                                            case SensorType.Temperature:
                                                if (s.Name.Equals("CPU Package"))
                                                    data[1] = Math.Round((double)s.Value).ToString();
                                                break;
                                            case SensorType.Load:
                                                if (s.Name.Contains("Total"))
                                                    data[2] = (Math.Round(s.Value.GetValueOrDefault(0))).ToString();
                                                break;
                                        }
                                        break;
                                    case HardwareType.RAM:
                                        if (s.SensorType == SensorType.Load)
                                            data[3] = (Math.Round(s.Value.GetValueOrDefault(0))).ToString();
                                        break;
                                    case HardwareType.GpuNvidia:
                                        switch (s.SensorType)
                                        {
                                            case SensorType.Clock:
                                                if (s.Name.Equals("GPU Core"))
                                                {
                                                    double v = Math.Round(s.Value.GetValueOrDefault(0));
                                                    if(v > 0)
                                                        data[4] = v.ToString();
                                                }
                                                break;
                                            case SensorType.Temperature:
                                                if (s.Name.Equals("GPU Core"))
                                                    data[5] = (Math.Round(s.Value.GetValueOrDefault(0))).ToString();
                                                break;
                                            case SensorType.Load:
                                                if (s.Name.Equals("GPU Core"))
                                                    data[6] = (Math.Round(s.Value.GetValueOrDefault(0))).ToString();
                                                else if (s.Name.Equals("GPU Memory"))
                                                    data[7] = (Math.Round(s.Value.GetValueOrDefault(0))).ToString();
                                                break;
                                        }
                                        break;
                                }
                            }
                        }

                        try
                        {
                            _serialPort.Write("temps");
                            foreach (string s in data)
                            {
                                _serialPort.Write(" ");
                                _serialPort.Write(s);
                            }
                            _serialPort.Write(_serialPort.NewLine);
                        }
                        catch (Exception)
                        {
                            break;
                        }
                    }
                    else
                    {
                        try
                        {
                            _serialPort.WriteLine("screen off");
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
                    Thread.Sleep(1000);
                }
            }
        }

        private static void PowerManager_IsMonitorOnChanged(object sender, EventArgs e)
        {
            screenStatus = PowerManager.IsMonitorOn;
        }
    }
}
