import '../../../backend/lib/database/database.dart';

Map<String, dynamic> adminToPublicJson(AdminData Admin){
  return{
    'id_admin': Admin.idAdmin,
    'nome': Admin.nome,
    'email': Admin.email,
    'telefone': Admin.telefone,
  };
}