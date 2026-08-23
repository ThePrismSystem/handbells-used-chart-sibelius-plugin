	_SettingsDialog "Dialog"
	{
		Title "Create a Handbells/Handchimes Used Chart"
		X "332"
		Y "272"
		Width "199"
		Height "201"
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
				Title "Handbells Used"
				X "88"
				Y "13"
				Width "60"
				Height "14"
				ID "dlg_bellLabel"
				Value
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
				Title "Handchimes Used"
				X "87"
				Y "29"
				Width "60"
				Height "14"
				ID "dlg_chimeLabel"
				Value
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
				X "87"
				Y "47"
				Width "60"
				Height "14"
				ID "dlg_chimeColor"
				Value
				Method
				SetFocus "0"
			}
			CheckBox
			{
				Title "Remove Existing Chart"
				X "77"
				Y "69"
				Width "76"
				Height "14"
				ID "dlg_remove"
				Value
				Method
				SetFocus "0"
			}
			Button
			{
				Title "OK"
				X "97"
				Y "91"
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
				Y "91"
				Width "50"
				Height "14"
				DefaultButton "0"
				ID "IDC_CANCEL_BUTTON"
				Value
				Method
				SetFocus "0"
				EndDialog "0"
			}
		}
	}