Add-Type -TypeDefinition @'
using System.Runtime.InteropServices;
[Guid("5CDF2C82-841E-4546-9722-0CF74078229A"), InterfaceType(ComInterfaceType.InterfaceIsIUnknown)]
interface IAudioEndpointVolume
{
    // f(), g(), ... are unused COM method slots. Define these if you care
    int f(); int g(); int h(); int i();
    int SetMasterVolumeLevelScalar(float fLevel, System.Guid pguidEventContext);
    int j();
    int GetMasterVolumeLevelScalar(out float pfLevel);
    int k(); int l(); int m(); int n();
    int SetMute([MarshalAs(UnmanagedType.Bool)] bool bMute, System.Guid pguidEventContext);
    int GetMute(out bool pbMute);
}
[Guid("D666063F-1587-4E43-81F1-B948E807363F"), InterfaceType(ComInterfaceType.InterfaceIsIUnknown)]
interface IMMDevice
{
    int Activate(ref System.Guid id, int clsCtx, int activationParams, out IAudioEndpointVolume aev);
}
[Guid("A95664D2-9614-4F35-A746-DE8DB63617E6"), InterfaceType(ComInterfaceType.InterfaceIsIUnknown)]
interface IMMDeviceEnumerator
{
    int f(); // Unused
    int GetDefaultAudioEndpoint(int dataFlow, int role, out IMMDevice endpoint);
}
[ComImport, Guid("BCDE0395-E52F-467C-8E3D-C4579291692E")] class MMDeviceEnumeratorComObject { }
public class Audio
{
    static IAudioEndpointVolume Vol()
    {
        var enumerator = new MMDeviceEnumeratorComObject() as IMMDeviceEnumerator;
        IMMDevice dev = null;
        Marshal.ThrowExceptionForHR(enumerator.GetDefaultAudioEndpoint(/*eRender*/ 0, /*eMultimedia*/ 1, out dev));
        IAudioEndpointVolume epv = null;
        var epvid = typeof(IAudioEndpointVolume).GUID;
        Marshal.ThrowExceptionForHR(dev.Activate(ref epvid, /*CLSCTX_ALL*/ 23, 0, out epv));
        return epv;
    }
    public static float Volume
    {
        get { float v = -1; Marshal.ThrowExceptionForHR(Vol().GetMasterVolumeLevelScalar(out v)); return v; }
        set { Marshal.ThrowExceptionForHR(Vol().SetMasterVolumeLevelScalar(value, System.Guid.Empty)); }
    }
    public static bool Mute
    {
        get { bool mute; Marshal.ThrowExceptionForHR(Vol().GetMute(out mute)); return mute; }
        set { Marshal.ThrowExceptionForHR(Vol().SetMute(value, System.Guid.Empty)); }
    }
}
'@




Add-Type -AssemblyName presentationCore 
#[reflection.assembly]::loadwithpartialname("System.Windows.Media")  
  $wmplayer = New-Object System.Windows.Media.MediaPlayer
  
Function AcikRadioWindow()

{PlayAcikRadioLive
 [reflection.assembly]::loadwithpartialname("System.Windows.Forms")|Out-Null  
  [reflection.assembly]::loadwithpartialname("System.Drawing")|Out-Null 
  $AcikRadioForm=New-Object System.Windows.Forms.Form  -Property @{
   ClientSize=New-Object System.Drawing.Size -Property @{
     Width=250
     Height=200
   }
   Text="Açık Radyo"
   Name="AcikRadioForm"
 }  
 $AcikRadioForm.StartPosition=[System.Windows.Forms.FormStartPosition]::CenterScreen
 $AcikRadioForm.FormBorderStyle = [System.Windows.Forms.FormBorderStyle]::FixedSingle
 $AcikRadioForm.MaximizeBox=$false
 $iconFile="acikradio.ico"
 if(Test-Path  $iconFile -ErrorAction SilentlyContinue )
 {
    New-Object System.Drawing.Icon("acikradio.ico") 
    $AcikRadioForm.Icon = $formicon
 }  
 $StartX=80
 $StartY=10
 $Span=30
 $TopLabel    = CreateControl -ControlType "Label"  -Text "Açık Radyo" -X 60 -Y $StartY
 $StartButton = CreateControl -ControlType "Button" -Text "Start"     -X $StartX -Y ($StartY+$Span)
 $MuteButton  = CreateControl -ControlType "Button" -Text "Stop"     -X $StartX -Y ($StartY+2*$Span)
 $CloseButton = CreateControl -ControlType "Button" -Text "Quit"        -X $StartX -Y ($StartY+3*$Span)
 $SoundControl= CreateControl -ControlType "TrackBar" -Text "Sound:"       -X 190 -Y ($StartY+$Span)
 $SoundLabel  = CreateControl -ControlType "Label"  -Text "Sound:%50" -X 170 -Y 130
 $SoundControl.Orientation=[System.Windows.Forms.Orientation]::Vertical
 $SoundControl.Height=100
 $SoundControl.Value=5 #%50
 $SoundControl.Minimum=0
 $SoundControl.Maximum=10
 $SoundControl.SmallChange=1
 $SoundControl.LargeChange=2
 $SoundControl.TickFrequency=1
 $TopLabel.Height=30
 $StartButton.add_Click({PlayAcikRadioLive})
 $MuteButton.add_Click({Stop})
 $CloseButton.add_Click({
    Stop  
    if ($AcikRadioForm -ne $null)
    {
        $AcikRadioForm.Dispose()
    }
 })
 $SoundControl.add_ValueChanged({    
    [audio]::Volume=[single] $this.Value/10.0
    $SoundLabel.Text="Sound: %$([Math]::Round(100*[audio]::Volume))" 
 })
 $Font = New-Object System.Drawing.Font("Times New Roman",14,[System.Drawing.FontStyle]::Bold)
 $TopLabel.Font=$Font
 $TopLabel.Width=150
 $AcikRadioForm.Controls.Add($SoundLabel)
 $AcikRadioForm.Controls.Add($TopLabel)
 $AcikRadioForm.Controls.Add($StartButton)
 $AcikRadioForm.Controls.Add($MuteButton)
 $AcikRadioForm.Controls.Add($CloseButton)
 $AcikRadioForm.Controls.Add($SoundLabel)
 $AcikRadioForm.Controls.Add($SoundControl)
 $AcikRadioForm.add_FormClosing($handler_CloseButton_Click)
 $AcikRadioForm.ShowDialog()|Out-Null
 [audio]::Volume=0.5
}

Function PlayAcikRadioLive()
{ 
 Add-Type -AssemblyName presentationCore 
 $filepath = [uri] "http://stream.34bit.net/ar64.mp3" 
 $wmplayer.Open($filepath) 
 $wmplayer.Play() 
}

Function Stop
{
    $wmplayer.Stop()
    $wmplayer.Close()  
}


Function CreateControl
{ 
 Param(
 [parameter(Mandatory=$true)]  [string] $ControlType,
 [parameter(Mandatory=$true)]  [String] $Text,
 [parameter(Mandatory=$true)]  [Int] $X,
 [parameter(Mandatory=$true)]  [Int] $Y)
 $ObjectName=""
 if($ControlType.Equals("Button")) {$ObjectName="System.Windows.Forms.Button"}
 elseif($ControlType.Equals("Label")){$ObjectName="System.Windows.Forms.Label"}
 elseif($ControlType.Equals("TrackBar")){$ObjectName="System.Windows.Forms.TrackBar"}
 else{Write-Error "Error: Wrong ControlType:$($ControlType)"}
 $Control=New-Object $ObjectName -Property @{
  Location=New-Object System.Drawing.Point -Property @{
    X = $X 
   Y = $Y
  }
  Text=$Text  
 } 
  return $Control
}

Clear-Host
AcikRadioWindow
