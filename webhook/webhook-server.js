const http = require('http');
const crypto = require('crypto');
const { exec } = require('child_process');

const PORT = process.env.PORT || 9000;
const SECRET = process.env.WEBHOOK_SECRET || 'reviewflow_secure_webhook_secret_key';
const ENV = process.env.DEPLOY_ENV || 'production'; // staging | production
const WORKSPACE_DIR = process.env.WORKSPACE_DIR || 'd:/workspace/business-review-ai';

function verifySignature(body, signature) {
  if (!signature) return false;
  const hmac = crypto.createHmac('sha256', SECRET);
  const digest = 'sha256=' + hmac.update(body).digest('hex');
  return crypto.timingSafeEqual(Buffer.from(signature), Buffer.from(digest));
}

const server = http.createServer((req, res) => {
  if (req.method === 'POST' && req.url === '/webhook') {
    let body = '';
    
    req.on('data', chunk => {
      body += chunk.toString();
    });
    
    req.on('end', () => {
      const signature = req.headers['x-hub-signature-256'];
      if (!verifySignature(body, signature)) {
        console.warn('⚠️ Webhook blocked: HMAC signature verification failed.');
        res.writeHead(401, { 'Content-Type': 'text/plain' });
        return res.end('Invalid signature');
      }
      
      let payload;
      try {
        payload = JSON.parse(body);
      } catch (err) {
        res.writeHead(400, { 'Content-Type': 'text/plain' });
        return res.end('Invalid JSON payload');
      }
      
      const branch = payload.ref;
      const repoName = payload.repository ? payload.repository.name : '';
      
      console.log(`📡 Webhook received from repo: '${repoName}' on branch: '${branch}'`);
      
      // Auto-deploy strictly on push events to the 'master' branch
      if (branch === 'refs/heads/master') {
        res.writeHead(202, { 'Content-Type': 'text/plain' });
        res.end('Deployment triggered');
        
        console.log(`🚀 Starting automated deployment for '${repoName}' in '${ENV}' mode...`);
        
        // Execute self-contained deploy shell script
        const deployCmd = `bash "${WORKSPACE_DIR}/onboard/webhook/deploy.sh" "${repoName}" "${ENV}"`;
        exec(deployCmd, (error, stdout, stderr) => {
          if (error) {
            console.error(`❌ Deployment failed: ${error.message}`);
            return;
          }
          console.log(`\n✅ Deployment Logs for '${repoName}':\n${stdout}`);
          if (stderr) console.error(`⚠️ Warnings/Logs:\n${stderr}`);
        });
      } else {
        res.writeHead(200, { 'Content-Type': 'text/plain' });
        res.end(`Ignored push branch: ${branch}`);
      }
    });
  } else {
    res.writeHead(404, { 'Content-Type': 'text/plain' });
    res.end('Not Found');
  }
});

server.listen(PORT, () => {
  console.log(`🤖 GitHub Auto-Deploy Webhook Server listening on port ${PORT}...`);
  console.log(`🔧 Target Environment: ${ENV}`);
});
