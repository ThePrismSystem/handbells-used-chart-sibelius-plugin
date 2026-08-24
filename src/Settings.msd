_SettingsDialog "Dialog"
	{
		Title "Create a Handbells/Handchimes/SMBs Used Chart"
		X "333"
		Y "271"
		Width "198"
		Height "180"
		Controls
		{
			Text
			{
				Title "Handbell Notehead Type"
				X "22"
				Y "16"
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
				Y "12"
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
				Y "38"
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
				Y "34"
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
				Y "60"
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
				Y "56"
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
				Y "86"
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
				Y "82"
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
				Y "106"
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
				Y "102"
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
				Y "124"
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
				Y "146"
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
				Y "146"
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