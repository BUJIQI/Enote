from flask import Blueprint, request, jsonify
from bson.objectid import ObjectId
from datetime import datetime
import jwt
import bcrypt
from pymongo.errors import PyMongoError
from ..utils.auth import generate_token, decode_token
from .. import mongo

auth_bp = Blueprint('auth', __name__)

# 注册
@auth_bp.route('/register', methods=['POST'])
def register():
    data = request.json
    username = data.get('username')
    password = data.get('password')
    sync_enabled = data.get('sync_enabled')
    
    try:
        if mongo.db.users.find_one({'username': username}):
            return jsonify({'message': '用户已存在'}), 400
        
        # 加密密码
        hashed_password = bcrypt.hashpw(password.encode('utf-8'), bcrypt.gensalt())

        # 创建用户文档
        user = {
            'username': username,
            'password': hashed_password,
            'sync_enabled': sync_enabled
        }
        user_id = mongo.db.users.insert_one(user).inserted_id
        return jsonify({'message': '注册成功', 'userId': str(user_id)}), 201
    except PyMongoError as e:
        return jsonify({'message': '操作失败', 'error': str(e)}), 500

# 登录
@auth_bp.route('/login', methods=['POST'])
def login():
    data = request.json
    username = data.get('username')
    password = data.get('password')
    sync_enabled = data.get('sync_enabled')

    try:
        user = mongo.db.users.find_one({'username': username})
        if not user:
            return jsonify({'message': '用户不存在'}), 404

        # 验证密码
        if not bcrypt.checkpw(password.encode('utf-8'), user['password']):
            return jsonify({'message': '密码错误'}), 401

        # 更新用户登录时间
        mongo.db.users.update_one(
            {'_id': ObjectId(user['_id'])},
            {'$set': {'last_login': datetime.now(), 'sync_enabled': sync_enabled}})

        # 生成 JWT 令牌
        token = generate_token(username)
        return jsonify({'token': token}), 200
    except PyMongoError as e:
        return jsonify({'message': '操作失败', 'error': str(e)}), 500

# 重置密码
@auth_bp.route('/reset_password', methods=['POST'])
def reset_password():
    data = request.json
    username = data.get('username')
    new_password = data.get('new_password')

    try:
        user = mongo.db.users.find_one({'username': username})
        if not user:
            return jsonify({'message': '用户不存在'}), 404
        
        # 加密密码
        hashed_password = bcrypt.hashpw(new_password.encode('utf-8'), bcrypt.gensalt())

        mongo.db.users.update_one(
            {'username': username},
            {'$set': {'password': hashed_password}}
        )

        return jsonify({'message': '密码已重置'}), 200
    except PyMongoError as e:
        return jsonify({'message': '操作失败', 'error': str(e)}), 500

# 注销
@auth_bp.route('/logout', methods=['GET'])
def logout():
    # 验证 JWT 令牌
    token = request.headers.get('Authorization')
    if not token:
        return jsonify({'message': '未提供令牌'}), 401

    result = decode_token(token)
    if isinstance(result, dict) and 'error' in result:
        return jsonify(result), 401

    payload = result
    username = payload.get('username')
    if not username:
        return jsonify({'message': '令牌中未包含用户名'}), 401

    try:
        # 注销用户登录状态
        mongo.db.users.update_one(
            {'username': username},
            {'$set': {'last_logout': datetime.now()}}
        )

        return jsonify({'message': '已注销'}), 200
    except PyMongoError as e:
        return jsonify({'message': '操作失败', 'error': str(e)}), 500

# 单独修改云同步开关
@auth_bp.route('/sync_enabled', methods=['POST'])
def sync_enabled():
    # 验证 JWT 令牌
    token = request.headers.get('Authorization')
    if not token:
        return jsonify({'message': '未提供令牌'}), 401

    result = decode_token(token)
    if isinstance(result, dict) and 'error' in result:
        return jsonify(result), 401

    payload = result
    username = payload.get('username')
    if not username:
        return jsonify({'message': '令牌中未包含用户名'}), 401

    # 修改云同步开关
    data = request.json
    sync_enabled = data.get('sync_enabled')

    try:
        mongo.db.users.update_one(
            {'username': username},
            {'$set': {'sync_enabled': sync_enabled}}
        )

        return jsonify({'message': '云同步状态已修改'}), 200
    except PyMongoError as e:
        return jsonify({'message': '操作失败', 'error': str(e)}), 500

# 编辑用户信息
@auth_bp.route('/edit_user_info', methods=['POST'])
def edit_user_info():
    # 验证 JWT 令牌
    token = request.headers.get('Authorization')
    if not token:
        return jsonify({'message': '未提供令牌'}), 401

    result = decode_token(token)
    if isinstance(result, dict) and 'error' in result:
        return jsonify(result), 401

    payload = result
    username = payload.get('username')
    if not username:
        return jsonify({'message': '令牌中未包含用户名'}), 401

    # 编辑用户信息
    data = request.json
    new_username = data.get('new_username')
    new_password = data.get('new_password')

    try:
        if new_username:
            if mongo.db.users.find_one({'username': new_username}):
                return jsonify({'message': '用户名已存在'}), 400
            mongo.db.users.update_one(
                {'username': username},
                {'$set': {'username': new_username}}
            )

        if new_password:
            hashed_password = bcrypt.hashpw(new_password.encode('utf-8'), bcrypt.gensalt())
            mongo.db.users.update_one(
                {'username': username},
                {'$set': {'password': hashed_password}}
            )

        return jsonify({'message': '用户信息已修改'}), 200
    except PyMongoError as e:
        return jsonify({'message': '操作失败', 'error': str(e)}), 500


