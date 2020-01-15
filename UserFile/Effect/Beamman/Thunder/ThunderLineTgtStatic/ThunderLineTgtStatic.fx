//--------------------------------------------------------------//
// lineSystem
// �������ЂƁF���x���A
// �x�[�X�ɂ����V�F�[�_�\�FLineSystem
// ���������F2010/10/9
// ���������ꂫ
// 10/10/9:������
//--------------------------------------------------------------//

//�������@�̐ݒ�
//
//�����������F
//BLENDMODE_SRC SRCALPHA
//BLENDMODE_DEST INVSRCALPHA
//
//���Z�����F
//
//BLENDMODE_SRC SRCALPHA
//BLENDMODE_DEST ONE

#define BLENDMODE_SRC SRCALPHA
#define BLENDMODE_DEST ONE

//���ˎ��ԃI�t�Z�b�g
float ShotOffset = 0;
//���ˎ��ԃI�t�Z�b�g�i�����_���l�j
float ShotRandOffset = 0;

//�^�[�Q�b�g�̖��O
float3 TgtPos : CONTROLOBJECT < string name = "tgt.x"; >;

//�����̖{��
int CloneNum = 10;

//�W�O�U�O�̃����_����
float ThunderRand = 1;

//�W�O�U�O�͈̔�
float ThunderRange = 3;

//�����_���p�����l�i�����o�������A�^�������������ɂȂ�Ȃ��ׂɂ����͕ς��Ă����Ƌg�j
float RandSeed = 0;

//�r���{�[�h�t���O�i�p�x�Ƃ̕��p�s�B�r���{�[�h���D�悳���j
#define BILLBORAD true

//�p�x�i0�`360�����j
#define ROTATE 0

//�ˏo���̐���
float3 StartSpd =  float3( 0,0,0 );

//���e���̐���
float3 EndSpd =  float3( 0,0,0 );

//�e�N�X�`����
texture Line_Tex
<
   string ResourceName = "Line.png";
>;

//���C���̑����iMMD��Őݒ肵�������~�����Őݒ肵���������\������鑾���j
float lineSize = float( 1 );

//UV�X�N���[�����x
float UScroll = float(2);
float VScroll = float(0);

//UV�J��Ԃ���
float UWrapNum = float(1);
float VWrapNum = float(1);

//--�悭�킩��Ȃ��l�͂������牺�͂�������Ⴞ��--//

//���C���̒����F�ύX�s��
#define LINE_LENGTH 100

float4   MaterialDiffuse   : DIFFUSE  < string Object = "Geometry"; >;

float time_0_X : TIME <bool SyncInEditMode=false;>;

//�΂̒l
#define PI 3.1415
//�p�x�����W�A���l�ɕϊ�
#define RAD ((ROTATE * PI) / 180.0)

float4x4 world_matrix : World;
float4x4 view_proj_matrix : ViewProjection;
float4x4 view_trans_matrix : ViewTranspose;

struct VS_OUTPUT {
   float4 Pos: POSITION;
   float2 texCoord: TEXCOORD0;
   float color: TEXCOORD1;
};

//�G���~�[�g�⊮�֐�
float3 HermiteLerp(float3 s,float3 e,float3 svec,float3 evec,float t)
{
	return (((t-1)*(t-1))*(2*t+1)*s) + ((t*t)*(3-2*t)*e) +((1-(t*t))*t*svec) + ((t-1)*(t*t)*evec);
}
//�ۑ��p�ϐ�
int index = 0;

//���̔��ˎ���
float ThunderWaitTime = 60;

VS_OUTPUT lineSystem_Vertex_Shader_main(float4 Pos: POSITION){
   VS_OUTPUT Out;

   int idx = round(Pos.z*LINE_LENGTH);
   //ID���K��̒�����蒷��������ő�l�ɌŒ�
   if(idx >= LINE_LENGTH)
   {
		idx = LINE_LENGTH-1;
   }
   
   
   
   //������ID
   float fid = 1.0 - (float) idx / (float)LINE_LENGTH;
   //����ID
   float fnextid = 1.0 - (float) (idx+1) / (float)LINE_LENGTH;
   
   float findex = index;
	float offset = findex*(ThunderWaitTime / (CloneNum*ThunderWaitTime)) + sin(findex)*ShotRandOffset;
	float time_buf = time_0_X + offset;
    float t = time_buf*60;
    
	//���[���h�̃x�N�g��
	float3 wvec = normalize(world_matrix[2].xyz);

	//���[���h��]�s����쐬�@���[���h�}�g���b�N�X���R�s�[����
	float4x4 world_rotate = world_matrix;
	//�ړ�������������
	world_rotate[3] = 0;

	//�n�_�A�I�_�x�N�g�������[���h��]
	StartSpd = mul(StartSpd,world_rotate);
	EndSpd = mul(EndSpd,world_rotate);


	//�n�_�x�N�g��
	float3 svec = StartSpd;

	//�I�_�x�N�g��
	float3 evec = -EndSpd;

   //0�_�̍��W
   float3 wpos = world_matrix[3].xyz;

	//�ڕW���W������
	int nw = t/ThunderWaitTime;

	nw += index + nw*123;
	float w = nw;

    //���݂̈ړ����W
    float3 nowpos = HermiteLerp(wpos,TgtPos,svec,evec,fid);
    
    //�����W
    float3 nextpos = HermiteLerp(wpos,TgtPos,svec,evec,fnextid);
    

   float3 pos = Pos;
   pos.z = 0;      

   float4 rspos = 0;
   if(BILLBORAD)
   {
	    //���C���̃r���{�[�h��
	    float3 vec = normalize(nowpos - nextpos);

		//�J��������̃x�N�g��
		float3 eyevec = normalize(view_trans_matrix[2].xyz);

		//�i�s�x�N�g���ƃJ�����x�N�g���̊O�ςŉ������𓾂�
		float3 side = normalize(cross(vec,eyevec));

		//�����ɍ��킹�Ċg��
		side *= lineSize/16;

		//���[���h�g�嗦�ɍ��킹�Ċg��i������
		side *= length(world_matrix[0]);

		//���͍��W��X�l�Ń��[�J���ȍ��E����
		if(Pos.x > 0)
		{
		    //����
		    rspos += float4(side,0);
		}else{
		    //�E��
		    rspos -= float4(side,0);
		}
	   
   }else{
	   pos *= lineSize;
       rspos = float4(pos,0);
	   //��r���{�[�h���C������
	   //���[�J����]����
	   //��]�s��̍쐬
	   float4x4 matRot;
	   matRot[0] = float4(cos(RAD),sin(RAD),0,0); 
	   matRot[1] = float4(-sin(RAD),cos(RAD),0,0); 
	   matRot[2] = float4(0,0,1,0); 
	   matRot[3] = float4(0,0,0,1); 
	   rspos = mul(rspos,matRot);
   }
   pos.x = rspos.x;
   pos.y = rspos.y;
   pos.z = rspos.z;
   

   
   idx /= ThunderRange;
   pos.x += sin(RandSeed+index+idx*1)*ThunderRand;
   pos.y += sin(RandSeed+index+idx*23)*ThunderRand;
   pos.z += sin(RandSeed+index+idx*456)*ThunderRand;

   pos += nowpos;
   
   Out.Pos = mul(float4(pos, 1), view_proj_matrix);

   
   t %= ThunderWaitTime;
   if(t > ThunderWaitTime/2 * (60/ThunderWaitTime))
   {
   		t = 0;
   }else{
   		t = 1;
   }
   
   //���_UV�l�̌v�Z
   Out.texCoord.x = Pos.z * UWrapNum * 0.5;
   Out.texCoord.y = ((Pos.x + Pos.y) + 0.5) * -VWrapNum;
   //UV�X�N���[��
   Out.texCoord.x += float2(UScroll,VScroll) * time_buf;
   Out.texCoord *= t;
   Out.color = t;

   return Out;
}
sampler LineTexSampler = sampler_state
{
   //�g�p����e�N�X�`��
   Texture = (Line_Tex);
   //�e�N�X�`���͈�0.0�`1.0���I�[�o�[�����ۂ̏���
   //WRAP:���[�v
   ADDRESSU = WRAP;
   ADDRESSV = WRAP;
   //�e�N�X�`���t�B���^�[
   //LINEAR:���`�t�B���^
   MAGFILTER = LINEAR;
   MINFILTER = LINEAR;
   MIPFILTER = LINEAR;
};
float4 lineSystem_Pixel_Shader_main(VS_OUTPUT IN,float2 texCoord: TEXCOORD0) : COLOR {
	float4 col = float4(tex2D(LineTexSampler,texCoord));
	col.a *= MaterialDiffuse.a;
	if(texCoord.x < 1)
	{
		col = 0;
	}

   return col;
}

technique lineSystem <
    string Script = 
        "RenderColorTarget0=;"
	    "RenderDepthStencilTarget=;"
	    
		"LoopByCount=CloneNum;"
        "LoopGetIndex=index;"
	    "Pass=lineSystem;"
        "LoopEnd=;"
    ;
> {
   pass lineSystem
   {
      ZENABLE = TRUE;
      ZWRITEENABLE = FALSE;
      CULLMODE = NONE;
      ALPHABLENDENABLE = TRUE;
      SRCBLEND=BLENDMODE_SRC;
      DESTBLEND=BLENDMODE_DEST;
      VertexShader = compile vs_3_0 lineSystem_Vertex_Shader_main();
      PixelShader = compile ps_3_0 lineSystem_Pixel_Shader_main();
   }
}
