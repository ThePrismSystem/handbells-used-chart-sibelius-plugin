_SettingsDialog "Dialog"
	{
		Title "Create a Handbells/Handchimes Used Chart"
		X "333"
		Y "271"
		Width "198"
		Height "203"
		Controls
		{
			Text
			{
				Title "Handbell Label"
				X "23"
				Y "15"
				Width "52"
				Height "14"
				RightAlign "0"
				ID "IDC_HANDBELL_LABEL_STATIC"
				Value
				Method
				SetFocus "0"
			}
			Edit
			{
				Title
				X "99"
				Y "13"
				Width "84"
				Height "14"
				ID "dlg_bellLabel"
				Value "dlg_bellLabel"
				Method
				SetFocus "0"
			}
			Text
			{
				Title "Handchime Label"
				X "23"
				Y "33"
				Width "52"
				Height "14"
				RightAlign "0"
				ID "IDC_HANDCHIME_LABEL_STATIC"
				Value
				Method
				SetFocus "0"
			}
			Edit
			{
				Title
				X "99"
				Y "31"
				Width "83"
				Height "14"
				ID "dlg_chimeLabel"
				Value "dlg_chimeLabel"
				Method
				SetFocus "0"
			}
			Text
			{
				Title "Handchime Color"
				X "23"
				Y "52"
				Width "51"
				Height "14"
				RightAlign "0"
				ID "IDC_HANDCHIME_COLOR_STATIC"
				Value
				Method
				SetFocus "0"
			}
			Edit
			{
				Title
				X "99"
				Y "48"
				Width "83"
				Height "14"
				ID "dlg_chimeColor"
				Value "dlg_chimeColor"
				Method
				SetFocus "0"
			}
			CheckBox
			{
				Title "Remove Existing Chart"
				X "75"
				Y "113"
				Width "76"
				Height "14"
				ID "dlg_remove"
				Value "dlg_remove"
				Method
				SetFocus "0"
			}
			Button
			{
				Title "OK"
				X "97"
				Y "133"
				Width "50"
				Height "14"
				DefaultButton "0"
				ID "IDC_OK_BUTTON"
				Value
				Method
				SetFocus "0"
				EndDialog "1"
			}
			Button
			{
				Title "Cancel"
				X "28"
				Y "133"
				Width "50"
				Height "14"
				DefaultButton "0"
				ID "IDC_CANCEL_BUTTON"
				Value
				Method
				SetFocus "0"
				EndDialog "0"
			}
			ComboBox
			{
				Title
				X "95"
				Y "66"
				Width "95"
				Height "21"
				ListVar "_BellHeadItems"
				AllowMultipleSelections "0"
				ID "dlg_bellHead"
				Value "dlg_bellHead"
				Method
				SetFocus "0"
			}
			ComboBox
			{
				Title
				X "94"
				Y "85"
				Width "95"
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
				Title "Handbell Notehead Type"
				X "22"
				Y "70"
				Width "67"
				Height "14"
				RightAlign "0"
				ID "IDC_HANDBELL_NOTEHEAD_STATIC"
				Value
				Method
				SetFocus "0"
			}
			Text
			{
				Title "Handchime Notehead Type"
				X "22"
				Y "90"
				Width "74"
				Height "14"
				RightAlign "0"
				ID "IDC_HANDCHIME_NOTEHEAD_STATIC"
				Value
				Method
				SetFocus "0"
			}
		}
	}