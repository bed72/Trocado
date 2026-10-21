<!DOCTYPE html>
<html lang="pt-BR">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <meta name="color-scheme" content="light">
    <title>Recuperação de senha do Trocado</title>
</head>
<body style="margin: 0; padding: 0; background-color: #F6FBF4; color: #181D19; font-family: Arial, Helvetica, sans-serif;">
    <table role="presentation" cellspacing="0" cellpadding="0" border="0" width="100%" style="background-color: #F6FBF4;">
        <tr>
            <td align="center" style="padding: 32px 16px;">
                <table role="presentation" cellspacing="0" cellpadding="0" border="0" width="100%" style="max-width: 520px; background-color: #FFFFFF; border: 1px solid #C0C9C0; border-radius: 20px;">
                    <tr>
                        <td style="padding: 40px 36px;">
                            <p style="margin: 0 0 36px; color: #2B6A46; font-size: 24px; font-weight: 700; line-height: 1.25;">Trocado</p>

                            <h1 style="margin: 0 0 14px; color: #181D19; font-size: 28px; font-weight: 700; line-height: 1.25;">Redefina sua senha</h1>

                            <p style="margin: 0 0 14px; color: #414942; font-size: 16px; line-height: 1.5;">Recebemos uma solicitação para redefinir a senha da sua conta no Trocado. Use o botão abaixo para escolher uma nova senha.</p>

                            <p style="margin: 0 0 26px; color: #414942; font-size: 16px; line-height: 1.5;">Este link expira em 30 minutos a partir da solicitação.</p>

                            <table role="presentation" cellspacing="0" cellpadding="0" border="0" width="100%">
                                <tr>
                                    <td align="center" bgcolor="#2B6A46" style="background-color: #2B6A46; border-radius: 14px;">
                                        <a href="{{ $recoveryUrl }}" style="display: block; padding: 18px 16px; color: #FFFFFF; font-size: 16px; font-weight: 700; line-height: 1.25; text-align: center; text-decoration: none;">Redefinir senha</a>
                                    </td>
                                </tr>
                            </table>

                            <p style="margin: 28px 0 0; color: #414942; font-size: 12px; line-height: 1.5;">Se você não solicitou a recuperação de senha, ignore esta mensagem. Sua senha não será alterada.</p>

                            <p style="margin: 20px 0 0; color: #414942; font-size: 12px; line-height: 1.5;">Se o botão não funcionar, copie e cole este link no navegador:<br><a href="{{ $recoveryUrl }}" style="color: #2B6A46; text-decoration: underline; overflow-wrap: anywhere; word-break: break-all;">{{ $recoveryUrl }}</a></p>
                        </td>
                    </tr>
                </table>
            </td>
        </tr>
    </table>
</body>
</html>
