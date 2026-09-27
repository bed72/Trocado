<!DOCTYPE html>
<html lang="pt-BR">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <meta name="color-scheme" content="light">
    <title>Confirme seu e-mail no Trocado</title>
</head>
<body style="margin: 0; padding: 0; background-color: #F6FBF4; color: #181D19; font-family: Arial, Helvetica, sans-serif;">
    <table role="presentation" cellspacing="0" cellpadding="0" border="0" width="100%" style="background-color: #F6FBF4;">
        <tr>
            <td align="center" style="padding: 32px 16px;">
                <table role="presentation" cellspacing="0" cellpadding="0" border="0" width="100%" style="max-width: 520px; background-color: #FFFFFF; border: 1px solid #C0C9C0; border-radius: 20px;">
                    <tr>
                        <td style="padding: 40px 36px;">
                            <p style="margin: 0 0 36px; color: #2B6A46; font-size: 24px; font-weight: 700; line-height: 1.25;">Trocado</p>

                            <h1 style="margin: 0 0 14px; color: #181D19; font-size: 28px; font-weight: 700; line-height: 1.25;">Confirme seu e-mail</h1>

                            <p style="margin: 0 0 26px; color: #414942; font-size: 16px; line-height: 1.5;">Para confirmar seu endereço de e-mail e continuar no Trocado, clique no botão abaixo.</p>

                            <table role="presentation" cellspacing="0" cellpadding="0" border="0" width="100%">
                                <tr>
                                    <td align="center" bgcolor="#2B6A46" style="background-color: #2B6A46; border-radius: 14px;">
                                        <a href="{{ $verificationUrl }}" style="display: block; padding: 18px 16px; color: #FFFFFF; font-size: 16px; font-weight: 700; line-height: 1.25; text-align: center; text-decoration: none;">Confirmar e-mail</a>
                                    </td>
                                </tr>
                            </table>

                            <p style="margin: 28px 0 0; color: #414942; font-size: 12px; line-height: 1.5;">Se você não criou uma conta, ignore esta mensagem.</p>

                            <p style="margin: 20px 0 0; color: #414942; font-size: 12px; line-height: 1.5;">Se o botão não funcionar, copie e cole este link no navegador:<br><a href="{{ $verificationUrl }}" style="color: #2B6A46; text-decoration: underline; overflow-wrap: anywhere; word-break: break-all;">{{ $verificationUrl }}</a></p>
                        </td>
                    </tr>
                </table>
            </td>
        </tr>
    </table>
</body>
</html>
