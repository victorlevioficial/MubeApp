# Configuração de Autenticação Firebase - AppMube

## Configuração do Template de Email de Recuperação de Senha

### Opção 1: Configuração via Firebase Console (Recomendado)

1. Acesse o [Firebase Console](https://console.firebase.google.com/)
2. Selecione o projeto **Mube**
3. No menu lateral, clique em **Authentication**
4. Vá para a aba **Templates de email**
5. Localize o template **Redefinição de senha** (Password Reset)

#### Personalização do Template

**Assunto (Subject):**
```
Redefina sua senha do Mube
```

**Corpo do Email (Body):**
```html
<!DOCTYPE html>
<html>
<head>
  <meta charset="UTF-8">
  <style>
    body {
      font-family: 'Inter', -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
      background-color: #0A0A0A;
      color: #FFFFFF;
      margin: 0;
      padding: 0;
    }
    .container {
      max-width: 600px;
      margin: 0 auto;
      padding: 40px 20px;
    }
    .logo {
      text-align: center;
      margin-bottom: 32px;
    }
    .logo img {
      height: 50px;
    }
    .content {
      background-color: #141414;
      border-radius: 16px;
      padding: 32px;
      border: 1px solid rgba(255, 255, 255, 0.1);
    }
    h1 {
      color: #FFFFFF;
      font-size: 24px;
      font-weight: 600;
      margin: 0 0 16px 0;
    }
    p {
      color: #9CA3AF;
      font-size: 16px;
      line-height: 1.6;
      margin: 0 0 24px 0;
    }
    .button {
      display: inline-block;
      background: linear-gradient(135deg, #6366F1 0%, #8B5CF6 100%);
      color: #FFFFFF !important;
      text-decoration: none;
      padding: 16px 32px;
      border-radius: 12px;
      font-weight: 600;
      font-size: 16px;
      margin: 8px 0;
    }
    .button:hover {
      opacity: 0.9;
    }
    .footer {
      text-align: center;
      margin-top: 32px;
      padding-top: 32px;
      border-top: 1px solid rgba(255, 255, 255, 0.1);
    }
    .footer p {
      font-size: 14px;
      color: #6B7280;
      margin: 0;
    }
    .link {
      color: #6366F1;
      word-break: break-all;
    }
  </style>
</head>
<body>
  <div class="container">
    <div class="logo">
      <img src="https://firebasestorage.googleapis.com/v0/b/mube-63a93.firebasestorage.app/o/logo%20horizontal.svg?alt=media&token=bff9d003-f6bf-40c5-be1c-5dbc9a88d2c9" alt="Mube" width="150" height="50" style="display: block; margin: 0 auto;">
    </div>
    <div class="content">
      <h1>Redefina sua senha</h1>
      <p>Olá,</p>
      <p>Recebemos uma solicitação para redefinir a senha da sua conta no Mube. Clique no botão abaixo para criar uma nova senha:</p>
      <a href="%LINK%" class="button">Redefinir senha</a>
      <p style="margin-top: 24px;">Se você não solicitou esta alteração, pode ignorar este email. Sua senha atual continuará segura.</p>
      <p style="margin-top: 16px; font-size: 14px;">Ou copie e cole este link no seu navegador:<br>
      <span class="link">%LINK%</span></p>
    </div>
    <div class="footer">
      <p>© 2025 Mube. Todos os direitos reservados.</p>
      <p style="margin-top: 8px;">Este é um email automático, por favor não responda.</p>
    </div>
  </div>
</body>
</html>
```

### Opção 2: Configuração via Cloud Function (Avançado)

Se precisar de mais controle sobre o envio de emails, você pode usar uma Cloud Function para enviar emails personalizados via SendGrid, AWS SES ou outro serviço.

Exemplo com SendGrid:

```typescript
// functions/src/auth.ts
import {onUserCreated} from "firebase-functions/v2/identity";
import * as admin from "firebase-admin";
import sgMail from "@sendgrid/mail";

sgMail.setApiKey(process.env.SENDGRID_API_KEY!);

export const sendCustomPasswordReset = onUserCreated(async (event) => {
  const user = event.data;
  
  // Gerar link de redefinição personalizado
  const resetLink = await admin.auth().generatePasswordResetLink(user.email!);
  
  // Enviar email personalizado via SendGrid
  await sgMail.send({
    to: user.email!,
    from: "noreply@mube.app",
    subject: "Redefina sua senha do Mube",
    html: `
      <!-- Seu template HTML personalizado -->
      <a href="${resetLink}">Redefinir senha</a>
    `,
  });
});
```

## Configurações Adicionais

### URL de Redirecionamento Personalizado

Para redirecionar o usuário para uma URL específica do app após redefinir a senha:

1. No Firebase Console, vá em **Authentication** > **Settings**
2. Na seção **Authorized domains**, adicione seu domínio personalizado
3. Configure o **Action URL** para apontar para uma página de confirmação no seu app

Exemplo de URL de ação:
```
https://mube.app/auth/action?mode=resetPassword&oobCode={oobCode}
```

### Configuração do Projeto Flutter

No `AndroidManifest.xml`, adicione o deep link para capturar o link de redefinição:

```xml
<intent-filter>
  <action android:name="android.intent.action.VIEW" />
  <category android:name="android.intent.category.DEFAULT" />
  <category android:name="android.intent.category.BROWSABLE" />
  <data android:scheme="https" 
        android:host="mube.app" 
        android:pathPrefix="/auth/action" />
</intent-filter>
```

No `Info.plist` (iOS):

```xml
<key>CFBundleURLTypes</key>
<array>
  <dict>
    <key>CFBundleURLSchemes</key>
    <array>
      <string>mube</string>
    </array>
  </dict>
</array>
```

## Testando a Recuperação de Senha

1. Execute o app em modo debug
2. Na tela de login, clique em "Esqueceu a senha?"
3. Digite um email válido de teste
4. Verifique a caixa de entrada (e spam) do email
5. Clique no link recebido
6. Defina uma nova senha

## Troubleshooting

### Email não chega
- Verifique a pasta de spam/lixo eletrônico
- Confirme que o email está correto no Firebase Auth
- Verifique os logs do Firebase Functions (se usando função customizada)

### Link expirado
- O link padrão expira em 1 hora
- Solicite um novo link se necessário

### Erro ao redefinir senha
- Verifique se a nova senha atende aos requisitos mínimos (6+ caracteres)
- Confirme que o link não foi alterado durante o envio