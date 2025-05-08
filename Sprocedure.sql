-- Active: 1744049051852@@127.0.0.1@5432@postgres
--OR REPLACE: opcional
-- se o proc ainda não existir, ele será criado
-- se já existir, será substituído
CREATE OR REPLACE PROCEDURE sp_ola_procedures()
LANGUAGE plpgsql
AS $$
BEGIN
RAISE NOTICE 'Olá, procedures';
END;
$$;
CALL sp_ola_procedures( );

--Stored procedure: usando um parâmetro

-- criando
CREATE OR REPLACE PROCEDURE sp_ola_usuario (nome VARCHAR(200))
LANGUAGE plpgsql
AS $$
BEGIN
-- acessando parâmetro pelo nome
RAISE NOTICE 'Olá, %', nome;
-- assim também vale
END;
$$;
--colocando em execução
CALL sp_ola_usuario('Pedro');

-- (Parâmetros e seus diferentes modos)
--in entrada = valor na esntrada processa com um valor dado no inicio  
-- out saida = valor na saida processa com valores dentro da função 
-- inout = faz os dois 
-----vc precisa especificar qual paramero é qual se nao vai serr sempre in 

--maior valor entre dois parametros recebidos na entrada IN
----------------------------------modo(IN) variavel(valor1) tipo(INT) 
CREATE OR REPLACE PROCEDURE sp_acha_maior (IN valor1 INT, valor2 INT)
LANGUAGE plpgsql
AS $$
BEGIN
IF valor1 > valor2 THEN
RAISE NOTICE '% é o maior', $1;
ELSE
RAISE NOTICE '% é o maior', $2;
END IF;
END;
$$

-- colocando em execução
CALL sp_acha_maior (2, 3);

--OUT  
CREATE OR REPLACE PROCEDURE sp_acha_maior (OUT resultado INT, IN valor1 INT, IN valor2 INT)
LANGUAGE plpgsql
AS $$
BEGIN
    CASE
        WHEN valor1 > valor2 THEN
            resultado := valor1;
        ELSE
            resultado := valor2;
    END CASE;
END;
$$

--colocando em execução
-- vc precisa crir a variavel para o cliente ter aceso 
DO $$
DECLARE
resultado INT;
BEGIN
CALL sp_acha_maior (resultado, 10, 12);
RAISE NOTICE '% é o maior', resultado;
END;
$$

--INOUT
DROP PROCEDURE IF EXISTS sp_acha_maior;

-- criando
CREATE OR REPLACE PROCEDURE sp_acha_maior (INOUT valor1 INT, IN valor2 INT)
LANGUAGE plpgsql
AS $$
BEGIN
IF valor2 > valor1 THEN
valor1 := valor2;
END IF;
END;
$$
--entendendo o codigo 
-- se o valor 3 for maior que o valor 1 entao  o valor 1 se tornar o numero que esta contido no valor 2 se nao vai imprimir o valor 1 de qualquer forma 

-- colocando em execução
DO
$$
DECLARE
valor1 INT := 8;
valor2 INT := 6;
BEGIN
CALL sp_acha_maior(valor1, valor2);
RAISE NOTICE '% é o maior', valor1;
END;
$$

--parâmetros VARIADIC   permite que especifique uma coleção de tamanho maior ou igual a 1

CREATE OR REPLACE PROCEDURE sp_calcula_media ( VARIADIC valores INT [])
LANGUAGE plpgsql
AS $$
DECLARE
soma NUMERIC(10, 2) := 0;
valor INT;
BEGIN
FOREACH valor IN ARRAY valores LOOP
soma := soma + valor;
END LOOP;
--array_length calcula o número de elementos no array. O segundo parâmetro é o número de dimensões dele
RAISE NOTICE 'A média é %', soma / array_length(valores, 1);
END;
$$
-- entendendo o codigo 
--soma começa como um numero com 10 casas amtes da virgula e 2 casas depois da virgula e é começa vazio com o 0
--enquanto  vc for ver cada valor dentro dos valores ( aqui vc indica que é um ARRAY)  vc soma  e acaba o loop quando terminar os vaolores 
-- --array_length calcula o número de elementos no array. O segundo parâmetro é o número de dimensões dele as dimiensoes podem ser as colunas
-- vc indica a lista quando vc chama  sp (procedure)

-- 1 parâmetro
CALL sp_calcula_media(1);
-- 2 parâmetros
CALL sp_calcula_media(1, 2);
-- 6 parâmetros
CALL sp_calcula_media(1, 2, 5, 6, 1, 8);
-- não funciona pq foi dito que a dimensao no  rray_length é 1 
CALL sp_calcula_media (ARRAY[1, 2]);


-- Sprocedures implementação de um restaurante implementaremos o funcionamento básico de um restaurante 
--Criação de tabelas

--CLIENTES COD E NOME
DROP TABLE tb_cliente;
CREATE TABLE tb_cliente (cod_cliente SERIAL PRIMARY KEY,
                         nome VARCHAR(200) NOT NULL
                        );


--PEDIDO COD  DTCRIACAO  DTMODIFICACAO  STATUS FK-COD_CLIENTE 
DROP TABLE tb_pedido;
CREATE TABLE IF NOT EXISTS tb_pedido(cod_pedido SERIAL PRIMARY KEY,
                                     data_criacao TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                                     data_modificacao TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                                     status VARCHAR DEFAULT 'aberto',
                                     cod_cliente INT NOT NULL,
                          CONSTRAINT fk_cliente FOREIGN KEY (cod_cliente) REFERENCES
                                     tb_cliente(cod_cliente)
);

--DESCRIÇÃO DOS ITENS COD_TIPO DESCRICAO 
DROP TABLE tb_tipo_item;
CREATE TABLE tb_tipo_item(cod_tipo SERIAL PRIMARY KEY,
                          descricao VARCHAR(200) NOT NULL );
INSERT INTO tb_tipo_item (descricao) VALUES ('Bebida'), ('Comida');
SELECT * FROM tb_tipo_item;


-- ITENS COD   DESCRICAO   VALOR   FK-COD_TIPO
DROP TABLE tb_item;
CREATE TABLE IF NOT EXISTS tb_item(cod_item SERIAL PRIMARY KEY,
                                   descricao VARCHAR(200) NOT NULL,
                                   valor NUMERIC (10, 2) NOT NULL,
                                   cod_tipo INT NOT NULL,
                        CONSTRAINT fk_tipo_item FOREIGN KEY (cod_tipo) REFERENCES
                                    tb_tipo_item(cod_tipo)
);
INSERT INTO tb_item (descricao, valor, cod_tipo) VALUES
('Refrigerante', 7, 1), ('Suco', 8, 1), ('Hamburguer', 12, 2), ('Batata frita', 9, 2);
SELECT * FROM tb_item;

--PEDIDO COD  FK-COD_ITEM  FK-COD_PEDIDO
DROP TABLE tb_item_pedido;
CREATE TABLE IF NOT EXISTS tb_item_pedido(cod_item_pedido SERIAL PRIMARY KEY,
                                          cod_item INT,
                                          cod_pedido INT,
                                CONSTRAINT fk_item FOREIGN KEY (cod_item) REFERENCES tb_item (cod_item),
                                CONSTRAINT fk_pedido FOREIGN KEY (cod_pedido) REFERENCES tb_pedido (cod_pedido)
);

--procedures exemplos praticos para a lanchonete 

--ccadastro de novos clientes 
-- se um parâmetro com valor DEFAULT é especificado, aqueles que aparecem depois dele também deve ter valor DEFAULT
-- por padrao, na maioria das vezes, o codigo nao sera dito na chamada para que crie de forma serial o cod_cliente na tb_cliente automaticamente quando inserir o nome 

DROP PROCEDURE IF EXISTS sp_cadastrar_cliente;

CREATE OR REPLACE PROCEDURE sp_cadastrar_cliente (IN nome VARCHAR(200), IN codigo INT DEFAULT NULL)
LANGUAGE plpgsql
AS $$
BEGIN
    IF codigo IS NULL THEN
        INSERT INTO tb_cliente (nome) VALUES (nome);
    ELSE
        INSERT INTO tb_cliente (codigo, nome) VALUES (codigo, nome);
    END IF;
END;
$$

--cadastrando
CALL sp_cadastrar_cliente ('João da Silva');
CALL sp_cadastrar_cliente ('Maria Santos');
SELECT * FROM tb_cliente;

--=============================================================================================================
--EXERCICIOS
--=============================================================================================================

 -- 1 Adicione/crie uma tabela de log ao sistema do restaurante. 
 --Ajuste cada procedimento para que ele registre a data em que a operação aconteceu o nome do procedimento executado
 DROP TABLE tb_log;

 CREATE TABLE tb_log (cod_log SERIAL pRIMARY KEY,
                     nome_log VARCHAR (200) NOT NULL,
                     dt_log TIMESTAMP DEFAULT CURRENT_TIMESTAMP);

DROP PROCEDURE IF EXISTS sp_cadastrar_cliente;

CREATE OR REPLACE PROCEDURE sp_cadastrar_cliente ( IN nome VARCHAR(200), IN codigo INT DEFAULT NULL )
LANGUAGE plpgsql
AS $$
BEGIN
    IF codigo IS NULL THEN
        INSERT INTO tb_cliente (nome) VALUES (nome);
    ELSE
        INSERT INTO tb_cliente (codigo, nome) VALUES (codigo, nome);
    END IF;
    INSERT INTO tb_log (nome_log) VALUES ('cadastrar_cliente');
END;
$$

CALL sp_cadastrar_cliente ('Amanda Oliveira');
CALL sp_cadastrar_cliente ('Julia Perez');
SELECT*FROM tb_log

--=============================================================================================================

-- 2 Adicione um procedimento ao sistema do restaurante. Ele deve receber um parâmetro de entrada (IN) que representa o código de um cliente  exibir, com RAISE NOTICE, o total de pedidos que o cliente tem
