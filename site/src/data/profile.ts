// Single source for everything the home and resume pages say about me.
// Edit here, and both pages update.

export const profile = {
  name: 'Jerome Aaron',
  role: 'Federal IT Specialist · Cloud Engineer',
  location: 'Washington, DC',
  linkedin: 'https://www.linkedin.com/in/jerome-aaron/',
  github: 'https://github.com/JeromeAaron',
  source: 'https://github.com/JeromeAaron/cloud-portfolio',
};

export const stats = [
  { value: '5 yrs', label: 'Supporting federal agencies' },
  { value: '4', label: 'Industry certifications' },
  { value: '99%+', label: 'Customer satisfaction on the service desk' },
  { value: '100%', label: "Of this site's AWS setup written in Terraform" },
];

export type SystemStatus = 'live' | 'running' | 'planned';

export const systems: {
  name: string;
  plain: string;
  tech: string[];
  status: SystemStatus;
  href: string;
}[] = [
  {
    name: 'jeromeaaron.com',
    plain: 'This website, hosted on AWS',
    tech: ['S3', 'CloudFront', 'WAF', 'Route 53', 'Terraform'],
    status: 'live',
    href: '/blog/building-cloud-portfolio',
  },
  {
    name: 'pi-stack homelab',
    plain: 'A private server that travels with me',
    tech: ['9 containers', 'Docker Compose', 'Ansible', 'Caddy', 'Tailscale'],
    status: 'running',
    href: '/blog/pi-stack-portable-homelab',
  },
  {
    name: 'Local AI lab',
    plain: 'Private AI models on my own laptop',
    tech: ['Ollama', 'Qwen3.6 35B', '~25 tokens/s', 'CUDA'],
    status: 'running',
    href: '/blog/pi-stack-portable-homelab#a-small-ai-and-machine-learning-lab',
  },
  {
    name: 'Hybrid cloud backup',
    plain: 'Offsite backups from the homelab to AWS',
    tech: ['S3 Glacier', 'Lambda', 'IAM', 'Terraform'],
    status: 'planned',
    href: '/blog/hybrid-cloud-homelab-aws',
  },
];

export const pipeline = [
  { tool: 'git push', plain: 'I commit a change' },
  { tool: 'GitHub Actions', plain: 'Type check, link check and accessibility audit' },
  { tool: 'Amazon S3', plain: 'Private file storage' },
  { tool: 'CloudFront + WAF', plain: 'Global delivery behind a firewall' },
  { tool: 'jeromeaaron.com', plain: 'Live for you minutes later' },
];

export const safeguards = [
  'Deploys sign in to AWS with short-lived OIDC credentials. No AWS keys are stored in GitHub.',
  'The S3 bucket is private. Only CloudFront can read from it.',
  'A web application firewall and strict security headers cover every request.',
  'Every GitHub Action is pinned to an exact commit, not a tag that can move.',
];

export const certifications = [
  { name: 'AWS Certified Solutions Architect – Associate', short: 'AWS Solutions Architect', issuer: 'Amazon Web Services', code: 'SAA-C03' },
  { name: 'CompTIA Security+', short: 'Security+', issuer: 'CompTIA', code: 'SY0-701' },
  { name: 'CompTIA A+', short: 'A+', issuer: 'CompTIA', code: '220-1101/02' },
  { name: 'ITIL® 4 Foundation', short: 'ITIL 4', issuer: 'PeopleCert', code: 'ITIL4' },
];

export const experience = [
  {
    role: 'IT Specialist',
    org: 'U.S. Small Business Administration',
    place: 'Washington, DC',
    dates: 'Nov 2024 – Present',
    summary: 'IT support for federally declared disaster response operations and Disaster Recovery Centers.',
    bullets: [
      'Spearhead IT support for federally declared disaster response operations, ensuring reliable technology services for field staff across multiple sites',
      'Provide Tier 2/3 technical support for Disaster Recovery Centers, managing IT readiness and resolving connectivity issues in challenging field environments',
      'Stabilize IT service delivery during rapid operational cycles, maintaining uptime for critical disaster relief systems',
      'Administer Identity and Access Management (IAM) protocols for user provisioning and access control across agency systems',
      'Develop and maintain system documentation, SOPs, and knowledge base articles for standardized incident response and configuration management',
      'Evaluate IT systems and services for effectiveness, recommending modern approaches aligned with industry best practices',
    ],
  },
  {
    role: 'Service Desk Technician',
    org: 'Iron Bow Technologies',
    place: 'Remote',
    dates: 'Sep 2021 – Dec 2024',
    summary: 'Tier 1/2 support for VA Telehealth: about 20 tickets a day at 99%+ customer satisfaction.',
    bullets: [
      'Delivered Tier 1/2 support for Department of Veterans Affairs Telehealth users via phone, email, and ticketing systems',
      'Consistently exceeded SLAs with a ticket-to-call ratio surpassing 100%, closing an average of 20 tickets per day',
      'Maintained a 99%+ customer satisfaction rating across all support interactions',
      'Collaborated with cross-functional teams including network services, software engineering, and vendors to restore services, identify root causes, and implement solutions',
      'Managed mobile device fleet using AirWatch WorkspaceOne UEM, enforcing security policies and organizational compliance',
      'Administered IAM protocols, facilitating access to critical business services while ensuring data security and regulatory compliance',
      'Coordinated asset lifecycle management including receipt, distribution, shipment, and disposition tracking',
    ],
  },
];

export const education = {
  degree: 'B.S. Cloud Computing',
  school: 'Western Governors University',
  dates: 'Expected Dec 2026',
};

export const skills = [
  { group: 'Cloud (AWS)', items: ['S3', 'CloudFront', 'Route 53', 'IAM', 'WAF', 'ACM'] },
  { group: 'Automation & CI/CD', items: ['Terraform', 'GitHub Actions', 'Ansible', 'Git', 'Bash', 'Astro'] },
  { group: 'Containers & Linux', items: ['Docker', 'Docker Compose', 'Linux', 'systemd', 'SELinux'] },
  { group: 'Networking & security', items: ['Tailscale / WireGuard', 'Caddy', 'Pi-hole', 'LUKS encryption', 'fail2ban'] },
  { group: 'Monitoring, backup & AI', items: ['Uptime Kuma', 'restic', 'Ollama', 'Open WebUI'] },
  { group: 'IT operations', items: ['Active Directory', 'Identity & access management', 'Endpoint management / MDM', 'Workspace ONE', 'Disaster recovery', 'Federal compliance', 'ITIL 4'] },
];

export const projects = [
  {
    name: 'This website',
    href: 'https://github.com/JeromeAaron/cloud-portfolio',
    external: true,
    summary: 'Static Astro site on private S3 behind CloudFront and WAF. Every AWS resource is defined in Terraform, and GitHub Actions tests and deploys each change.',
    tech: ['Astro', 'S3', 'CloudFront', 'Route 53', 'IAM', 'WAF', 'ACM', 'Terraform', 'GitHub Actions'],
  },
  {
    name: 'Pi-Stack homelab',
    href: '/blog/pi-stack-portable-homelab',
    external: false,
    summary: 'An encrypted Raspberry Pi server that travels with me: DNS, a password manager, document OCR and notes sync, rebuilt from an Ansible playbook. Heavy work like photo recognition and local AI runs on my laptop.',
    tech: ['Raspberry Pi', 'Docker Compose', 'Caddy', 'Tailscale', 'LUKS', 'Ansible', 'Ollama'],
  },
  {
    name: 'Hybrid cloud backup (in design)',
    href: '/blog/hybrid-cloud-homelab-aws',
    external: false,
    summary: 'Encrypted offsite copies of the homelab in S3 Glacier Deep Archive for about $3 a month, with least-privilege IAM and a Lambda watchdog, all in Terraform.',
    tech: ['S3', 'IAM', 'Lambda', 'EventBridge', 'SNS', 'Terraform', 'restic'],
  },
];
