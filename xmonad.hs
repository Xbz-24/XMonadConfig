import XMonad
import System.IO
import XMonad.Util.EZConfig
import XMonad.Util.Ungrab
import XMonad.Util.SpawnOnce
import XMonad.Util.Run(spawnPipe, safeSpawn)
import XMonad.Hooks.DynamicLog
import XMonad.Hooks.ManageDocks
import XMonad.Actions.PhysicalScreens
import XMonad.Actions.WindowBringer (WindowBringerConfig(..), gotoMenuConfig)
import qualified XMonad.StackSet as W
import XMonad.Layout.ResizableTile
import XMonad.Layout.Spiral
import XMonad.Layout.PerWorkspace
import XMonad.Layout.Simplest
import XMonad.Layout.Spacing
import XMonad.Layout.IndependentScreens;
import XMonad.Actions.CycleWindows
import XMonad.Operations (refresh)
import Data.Monoid (mappend)

altMask :: KeyMask
altMask = mod1Mask

myWorkspaceFilter :: [String] -> [String]
myWorkspaceFilter = filter (\ws -> ws `elem` ["1_1", "1_2", "1_3"])

--myWorkspaces = withScreens 2 ["1", "2", "3", "4", "5", "6", "7", "8", "9"]
myWorkspaces = withScreens 2 ["1", "2", "3"]

spiralLayout = spiral (6/7)

rofiGotoMenu :: X ()
rofiGotoMenu = gotoMenuConfig $ def 
    { menuCommand = "rofi", menuArgs = ["-dmenu", "-i", "-p", "goto: "] }

tall = spacing 17 $ ResizableTall nmaster delta ratio []

nmaster = 1     
ratio   = 1/2  
delta   = 3/100 

myStartupHook = do
    spawnOnce "feh --bg-scale /home/daily/Downloads/nasa_wall.jpg &"
    spawnOnce "emacs &"
    spawnOnce "spotify &"
    spawnOnce "brave-browser-nightly &"
    spawnOnce "kitty &"
    spawnOnce "discord &"
    spawnOnce "zapzap &"
    spawnOnce "telegram-cli &"
    spawnOnce "bitwarden &"
    spawnOnce "thunderbird &"

myLayout = avoidStruts(spiralLayout ||| Tall nmaster delta ratio ||| Full)
--myLayout = onWorkspace "1" (tall ||| Mirror tall ||| Full) $ onWorkspace "2" (Mirror tall ||| tall ||| Full) $ tall ||| Full

myLogHook xmprocs = mapM_ (\(xmproc, _) -> dynamicLogWithPP $ myXmobarPP xmproc) (zip xmprocs [0..])

myXmobarPP :: Handle -> PP
myXmobarPP xmproc = xmobarPP {
    ppLayout = xmobarColor "#1d60cc" "" . (\x -> case x of
                  "Tall" -> "Tall"
                  "Mirror Tall" -> "Mirror Tall"
                  "Full" -> "Full"
                  _ -> x),
    ppOutput = hPutStrLn xmproc,
    ppCurrent = xmobarColor "violet" "" . wrap "[" "]",
    ppVisible = xmobarColor "#ed8c2b" "" .wrap "[" "]",
    ppHidden = xmobarColor "#C98F0A" "" .wrap "[" "]",
    --ppHiddenNoWindows = xmobarColor "#C0C0C0" "",
    ppHiddenNoWindows = const "" .wrap,
    ppTitle = xmobarColor "violet" "" . shorten 50,
    ppOrder = \(ws:l:t:ex) -> [ws, l, t] ++ ex
}

main :: IO ()

main = do
    spawn "xrandr --output HDMI-0 --primary --mode 1920x1080 --rate 60 --output DP-4 --mode 1920x1080 --rate 144 --right-of HDMI-0 --rotate left"
    spawn "xset r rate 200 50"
    xmproc <- spawnPipe "xmobar"
    nScreens <- countScreens
    xmprocs <- mapM (\i -> spawnPipe $ "xmobar -x " ++ show i ++ " ~/.xmobarrc") [0..nScreens-1]
    xmonad $ docks def { 
    	  workspaces = myWorkspaces
        , focusedBorderColor = "#5D3891"
        , normalBorderColor  = "#F99417"
        , startupHook = myStartupHook
        , terminal    = "kitty"
        , modMask     = mod4Mask
        , borderWidth = 2
        , layoutHook  = myLayout
        , manageHook  = manageDocks <+>  manageHook def
        , logHook = myLogHook xmprocs
        }
        `additionalKeysP`
        [ ("M-p", spawn "rofi -show run")
        , ("M-S-p", rofiGotoMenu)
        , ("M-t", withFocused $ windows . W.sink)
        , ("M-,", onPrevNeighbour def W.view)
        , ("M-.", onNextNeighbour def W.view)
        , ("M-S-,", onPrevNeighbour def W.shift)
        , ("M-S-.", onNextNeighbour def W.shift)
        , ("M-h", sendMessage Shrink)       
        , ("M-l", sendMessage Expand)       
        , ("M-j", sendMessage MirrorShrink) 
        , ("M-k", sendMessage MirrorExpand) 
        , ("M-S-j", windows W.focusDown)
        , ("M-S-k", windows W.focusUp)
        , ("M-S-h", windows W.swapUp)      
        , ("M-S-l", windows W.swapDown)    
        , ("<XF86AudioRaiseVolume>", spawn "wpctl set-volume -l 2.0 @DEFAULT_AUDIO_SINK@ 5%+")
        , ("<XF86AudioLowerVolume>", spawn "wpctl set-volume -l 2.0 @DEFAULT_AUDIO_SINK@ 5%-")
        , ("<XF86AudioMute>", spawn "wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle")
        , ("<XF86AudioPlay>", spawn "playerctl play-pause && notify-send 'Play/Pause'")
        , ("<XF86AudioNext>", spawn "playerctl next && notify-send 'Next Track'")
        , ("<XF86AudioPrev>", spawn "playerctl previous && notify-send 'Previous Track'")
        , ("<Print>", spawn "flameshot gui")
        ]
        `additionalKeys`
        [
           ((altMask, xK_Tab), windows W.focusDown)
         , ((altMask .|. shiftMask, xK_Tab), windows W.focusUp)
        ]
