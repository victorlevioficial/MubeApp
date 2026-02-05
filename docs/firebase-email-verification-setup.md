# Configuração do Email de Verificação no Firebase

## Passo a Passo para Configurar o Template de Email

### 1. Acessar o Console do Firebase

1. Acesse: https://console.firebase.google.com
2. Selecione o projeto **mube-63a93**
3. No menu lateral, clique em **Authentication** → **E-mail** (ou **Templates**)

### 2. Configurar o Template de Verificação de Email

Na tela que você mostrou, configure os seguintes campos:

#### **Nome do remetente**
```
Mube
```

#### **De (Email)**
```
noreply@mubeapp.com.br
```

#### **Responder para**
```
suporte@mubeapp.com.br
```
(Ou deixe em branco para usar o mesmo "De")

#### **Assunto**
```
Verifique seu e-mail no Mube
```

#### **Mensagem** (Template HTML)

```html
<!DOCTYPE html>
<html>
<head>
  <meta charset="UTF-8">
  <style>
    body {
      font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
      background-color: #f5f5f5;
      margin: 0;
      padding: 20px;
    }
    .container {
      max-width: 600px;
      margin: 0 auto;
      background-color: #ffffff;
      border-radius: 12px;
      overflow: hidden;
      box-shadow: 0 4px 6px rgba(0, 0, 0, 0.1);
    }
    .header {
      background: linear-gradient(135deg, #FF6B35 0%, #FF8C42 100%);
      padding: 40px 20px;
      text-align: center;
    }
    .logo {
      width: 80px;
      height: 80px;
      margin-bottom: 16px;
    }
    .header h1 {
      color: #ffffff;
      margin: 0;
      font-size: 24px;
      font-weight: 600;
    }
    .content {
      padding: 40px 30px;
      color: #333333;
    }
    .greeting {
      font-size: 18px;
      margin-bottom: 20px;
    }
    .message {
      font-size: 16px;
      line-height: 1.6;
      margin-bottom: 30px;
      color: #666666;
    }
    .button-container {
      text-align: center;
      margin: 30px 0;
    }
    .button {
      display: inline-block;
      background: linear-gradient(135deg, #FF6B35 0%, #FF8C42 100%);
      color: #ffffff !important;
      text-decoration: none;
      padding: 16px 40px;
      border-radius: 30px;
      font-weight: 600;
      font-size: 16px;
      box-shadow: 0 4px 12px rgba(255, 107, 53, 0.3);
    }
    .fallback {
      margin-top: 30px;
      padding: 20px;
      background-color: #f8f9fa;
      border-radius: 8px;
      font-size: 14px;
      color: #666666;
    }
    .fallback a {
      color: #FF6B35;
      word-break: break-all;
    }
    .footer {
      padding: 30px;
      text-align: center;
      background-color: #f8f9fa;
      border-top: 1px solid #eeeeee;
    }
    .footer p {
      margin: 0;
      font-size: 14px;
      color: #999999;
    }
    .warning {
      margin-top: 20px;
      padding: 15px;
      background-color: #fff3cd;
      border-left: 4px solid #ffc107;
      border-radius: 4px;
      font-size: 14px;
      color: #856404;
    }
  </style>
</head>
<body>
  <div class="container">
    <div class="header">
      <img src="https://mube.app/logo.png" alt="Mube" class="logo">
      <h1>Verificação de E-mail</h1>
    </div>
    
    <div class="content">
      <p class="greeting">Olá, %DISPLAY_NAME%</p>
      
      <p class="message">
        Bem-vindo ao <strong>Mube</strong>! Estamos quase lá...<br><br>
        Para garantir a segurança da sua conta, precisamos confirmar seu endereço de e-mail. 
        Clique no botão abaixo para completar a verificação:
      </p>
      
      <div class="button-container">
        <a href="%LINK%" class="button">Verificar meu e-mail</a>
      </div>
      
      <div class="fallback">
        <p><strong>O botão não funcionou?</strong></p>
        <p>Copie e cole este link no seu navegador:</p>
        <p><a href="%LINK%">%LINK%</a></p>
      </div>
      
      <div class="warning">
        <strong>⚠️ Não solicitou esta verificação?</strong><br>
        Se você não criou uma conta no Mube, ignore este e-mail. 
        Sua segurança é importante para nós.
      </div>
    </div>
    
    <div class="footer">
      <p>© 2025 Mube. Todos os direitos reservados.</p>
      <p style="margin-top: 10px; font-size: 12px;">
        Este é um e-mail automático, por favor não responda.
      </p>
    </div>
  </div>
</body>
</html>
```

### 3. Configurar o Domínio de Ação (Action URL)

1. No Firebase Console, vá em **Authentication** → **Settings** → **Action URL settings**

2. Configure o **Action URL** para apontar para o seu app:
   - **Para iOS/Android**: Use o deep link do app
   ```
   https://mubeapp.page.link/verify
   ```
   
   - **Ou use o domínio padrão do Firebase** (já configurado):
   ```
   https://mube-63a93.firebaseapp.com/__/auth/action
   ```

3. Para configurar um domínio personalizado (opcional):
   - Vá em **Authentication** → **Settings** → **Authorized domains**
   - Adicione seu domínio personalizado
   - Configure o DNS conforme as instruções do Firebase

### 4. Configurar Deep Links (Para Abrir o App)

#### Android - `android/app/src/main/AndroidManifest.xml`:

Adicione dentro da tag `<activity>`:

```xml
<intent-filter>
    <action android:name="android.intent.action.VIEW" />
    <category android:name="android.intent.category.DEFAULT" />
    <category android:name="android.intent.category.BROWSABLE" />
    <data 
        android:scheme="https"
        android:host="mube-63a93.firebaseapp.com"
        android:pathPrefix="/__/auth/action" />
</intent-filter>

<!-- Para domínio personalizado -->
<intent-filter>
    <action android:name="android.intent.action.VIEW" />
    <category android:name="android.intent.category.DEFAULT" />
    <category android:name="android.intent.category.BROWSABLE" />
    <data 
        android:scheme="https"
        android:host="mube.app"
        android:pathPrefix="/verify" />
</intent-filter>
```

#### iOS - `ios/Runner/Info.plist`:

```xml
<key>CFBundleURLTypes</key>
<array>
  <dict>
    <key>CFBundleURLName</key>
    <string>com.mube.app</string>
    <key>CFBundleURLSchemes</key>
    <array>
      <string>com.mube.app</string>
    </array>
  </dict>
</array>
```

### 5. Configurar Dynamic Links (Firebase)

1. No Firebase Console, vá em **Engage** → **Dynamic Links**
2. Clique em **Get started**
3. Configure o prefixo de URL: `https://mubeapp.page.link`
4. Adicione o domínio do seu app nas configurações

### 6. Testar a Configuração

1. **Salve as alterações** no template de email
2. Execute o app e faça um novo registro
3. Verifique se o email chega com o template personalizado
4. Clique no link e confirme se o app abre corretamente

### 7. Configurações Adicionais (Opcional)

#### Tempo de Expiração do Link

No Firebase Console → Authentication → Templates:
- O link de verificação expira em **24 horas** por padrão
- Para alterar, contate o suporte do Firebase (não é possível alterar via console)

#### Personalização por Idioma

O Firebase já detecta o idioma do usuário automaticamente. Para adicionar mais idiomas:

1. No template, clique em **Idioma do modelo**
2. Selecione **Adicionar idioma**
3. Escolha o idioma desejado
4. Traduza o template

### Variáveis Disponíveis no Template

| Variável | Descrição | Exemplo |
|----------|-----------|---------|
| `%DISPLAY_NAME%` | Nome do usuário | "João Silva" |
| `%APP_NAME%` | Nome do app | "Mube" |
| `%LINK%` | Link de verificação | URL única |
| `%EMAIL%` | Email do usuário | "joao@email.com" |

### Solução de Problemas

#### Email cai na caixa de spam?
- Configure o SPF e DKIM no DNS do seu domínio
- Use um domínio personalizado em vez de @firebase.com

#### Link não abre o app?
- Verifique se os deep links estão configurados corretamente
- Teste usando o comando: `adb shell am start -W -a android.intent.action.VIEW -d "https://mube-63a93.firebaseapp.com/__/auth/action" com.mube.mubeoficial`

#### Template não salva?
- Verifique se não há caracteres inválidos no HTML
- O tamanho máximo do template é 64KB

---

## Resumo das Configurações

| Configuração | Valor |
|--------------|-------|
| Nome do remetente | `Mube` |
| Email remetente | `noreply@mubeapp.com.br` |
| Assunto | `Verifique seu e-mail no Mube` |
| Action URL | `https://mube-63a93.firebaseapp.com/__/auth/action` |
| Tempo de expiração | 24 horas |

Após configurar, teste o fluxo completo criando uma nova conta no app!
