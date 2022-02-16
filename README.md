# Python-EC2-CICD-Prototype

파이썬 Flask 프로젝트를 아마존 EC2 인스턴스와 연동하여 빠른 개발이 가능하도록 만들어둔 프로젝트 입니다.  

main branch push -> trigger -> GitAction 빌드 혹은 압축 후 AWS S3 로 업로드  
AWS CodePipeline 이 S3버킷을 감지하여 CodeDeploy 작동 -> CodeDeploy 가 디플로이 스크립트를 통해 디플로이  

디플로이 스크립트는 Nginx Reverse Proxy 를 사용하였습니다.    
새로운 리소스로 디플로이가 완료되면 health 체크 후 ok 응답을 받고  
기존의 프로세스를 종료하는 순 입니다.

nginx.conf에는 80포트로 진입시 443포트로 리디렉션 하도록 하였습니다.    

리버스 프록시와 함께 맞물려서 사용하기 때문에  
service_addr.inc를 참조하여 그 조소값 및 포트값 으로 변환하게끔 설정했습니다.  

nginx기동시에는   
ssl을 사용하기 때문에 ssl 인증키와 / 인증국 서명을 생성해 놓아야 합니다.

## 작업순서  
- GitAction 유저를 AWS IAM에서 만들어 놓아야 합니다
  - S3 버킷명을 프로젝트 시크릿에 설정 해 놓아야 합니다
  - GitAction 유저의 Access Key를 프로젝트 시크릿에 설정 해 놓아야 합니다
  - GitAction 유저의 Scret Key를 프로젝트 시크릿에 설정 해 놓아야 합니다.

> 여기까지 작업하여 GitAction으로 빌드 혹은 압축된 파일이 S3버킷까지 잘 전송 되는지 확인합니다  

- EC2 인스턴스에 Nginx를 설치
  - EC2인스턴스에 Nginx 를 먼저 설치합니다.
  - 포함된 service_addr.inc를 EC2인스턴스에 작성
  - 포함된 nginx.conf를 EC2인스턴스에서 수정
  - 자가 인증국 서명파일과 / 시크릿을 생성
> Nginx 는 sudo systemctl enable nginx 로 재부팅하여도 작동하도록 해놓습니다  

- IAM역할을 만듭니다 AmazonEC2RoleforAWSCodeDeploy
  - EC2인스턴스에서 방금만든 IAM을 적용합니다. (EC2 서비스에서 EC2선택 -> 보안 -> IAM역할 수정)  
- AWS 에서 CodeDeploy 를 설정합니다.

> CodeDeploy가 잘 작동하는지 확인합니다.  

- CodePipeline을 설정합니다


