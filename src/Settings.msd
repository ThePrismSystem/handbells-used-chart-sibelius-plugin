_SettingsDialog "Dialog"
	{
		Title "Create a Handbells/Handchimes/SMBs Used Chart"
		X "333"
		Y "271"
		Width "198"
		Height "308"
		Controls
		{
			Text
			{
				Title "Instruments to Chart"
				X "22"
				Y "16"
				Width "74"
				Height "14"
				RightAlign "0"
				ID "IDC_INSTRUMENTS_STATIC"
				Value
				Method
				SetFocus "0"
			}
			ListBox
			{
				Title
				X "98"
				Y "12"
				Width "92"
				Height "56"
				ListVar "_InstrumentItems"
				AllowMultipleSelections "1"
				ID "dlg_instruments"
				Value "dlg_instruments"
				Method "InstrumentsChanged"
				SetFocus "0"
			}
			Text
			{
				Title "Cmd-click (Ctrl-click on Windows) to pick more than one."
				X "98"
				Y "70"
				Width "92"
				Height "22"
				RightAlign "0"
				ID "IDC_INSTRUMENTS_HINT"
				Value
				Method
				SetFocus "0"
			}
			Text
			{
				Title "Charts"
				X "22"
				Y "98"
				Width "74"
				Height "14"
				RightAlign "0"
				ID "IDC_CHARTMODE_STATIC"
				Value
				Method
				SetFocus "0"
			}
			ComboBox
			{
				Title
				X "98"
				Y "94"
				Width "92"
				Height "21"
				ListVar "_ChartModeItems"
				AllowMultipleSelections "0"
				ID "dlg_chartMode"
				Value "dlg_chartMode"
				Method
				SetFocus "0"
			}
			CheckBox
			{
				Title "Also Add Charts to Parts"
				X "98"
				Y "118"
				Width "92"
				Height "14"
				ID "dlg_parts"
				Value "dlg_parts"
				Method
				SetFocus "0"
			}
			Text
			{
				Title "Handbell Notehead Type"
				X "22"
				Y "144"
				Width "74"
				Height "14"
				RightAlign "0"
				ID "IDC_BELLHEAD_STATIC"
				Value
				Method
				SetFocus "0"
			}
			ComboBox
			{
				Title
				X "98"
				Y "140"
				Width "92"
				Height "21"
				ListVar "_BellHeadItems"
				AllowMultipleSelections "0"
				ID "dlg_bellHead"
				Value "dlg_bellHead"
				Method
				SetFocus "0"
			}
			Text
			{
				Title "Handchime Notehead Type"
				X "22"
				Y "166"
				Width "74"
				Height "14"
				RightAlign "0"
				ID "IDC_CHIMEHEAD_STATIC"
				Value
				Method
				SetFocus "0"
			}
			ComboBox
			{
				Title
				X "98"
				Y "162"
				Width "92"
				Height "21"
				ListVar "_ChimeHeadItems"
				AllowMultipleSelections "0"
				ID "dlg_chimeHead"
				Value "dlg_chimeHead"
				Method
				SetFocus "0"
			}
			Text
			{
				Title "SMBs Notehead Type"
				X "22"
				Y "188"
				Width "74"
				Height "14"
				RightAlign "0"
				ID "IDC_SMBHEAD_STATIC"
				Value
				Method
				SetFocus "0"
			}
			ComboBox
			{
				Title
				X "98"
				Y "184"
				Width "92"
				Height "21"
				ListVar "_SmbHeadItems"
				AllowMultipleSelections "0"
				ID "dlg_smbHead"
				Value "dlg_smbHead"
				Method
				SetFocus "0"
			}
			Text
			{
				Title "Handchime Color"
				X "22"
				Y "214"
				Width "74"
				Height "14"
				RightAlign "0"
				ID "IDC_CHIMECOLOR_STATIC"
				Value
				Method
				SetFocus "0"
			}
			Edit
			{
				Title
				X "98"
				Y "210"
				Width "92"
				Height "14"
				ID "dlg_chimeColor"
				Value "dlg_chimeColor"
				Method
				SetFocus "0"
			}
			Text
			{
				Title "SMBs Color"
				X "22"
				Y "234"
				Width "74"
				Height "14"
				RightAlign "0"
				ID "IDC_SMBCOLOR_STATIC"
				Value
				Method
				SetFocus "0"
			}
			Edit
			{
				Title
				X "98"
				Y "230"
				Width "92"
				Height "14"
				ID "dlg_smbColor"
				Value "dlg_smbColor"
				Method
				SetFocus "0"
			}
			CheckBox
			{
				Title "Remove Existing Chart"
				X "98"
				Y "252"
				Width "92"
				Height "14"
				ID "dlg_remove"
				Value "dlg_remove"
				Method
				SetFocus "0"
			}
			Button
			{
				Title "Cancel"
				X "84"
				Y "274"
				Width "50"
				Height "14"
				DefaultButton "0"
				ID "IDC_CANCEL_BUTTON"
				Value
				Method
				SetFocus "0"
				EndDialog "0"
			}
			Button
			{
				Title "OK"
				X "140"
				Y "274"
				Width "50"
				Height "14"
				DefaultButton "0"
				ID "IDC_OK_BUTTON"
				Value
				Method
				SetFocus "0"
				EndDialog "1"
			}
		}
	}