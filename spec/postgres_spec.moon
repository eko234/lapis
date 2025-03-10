require "spec.helpers" -- for one_of

db = require "lapis.db.postgres"
schema = require "lapis.db.postgres.schema"

unpack = unpack or table.unpack

value_table = { hello: "world", age: 34 }

import sorted_pairs from require "spec.helpers"

tests = {
  -- lapis.db.postgres
  {
    -> db.escape_identifier "dad"
    '"dad"'
  }
  {
    -> db.escape_identifier "select"
    '"select"'
  }
  {
    -> db.escape_identifier 'love"fish'
    '"love""fish"'
  }
  {
    -> db.escape_identifier db.raw "hello(world)"
    "hello(world)"
  }
  {
    -> db.escape_literal 3434
    "3434"
  }
  {
    -> db.escape_literal "cat's soft fur"
    "'cat''s soft fur'"
  }
  {
    -> db.escape_literal db.raw "upper(username)"
    "upper(username)"
  }
  {
    -> db.escape_literal db.list {1,2,3,4,5}
    "(1, 2, 3, 4, 5)"
  }
  {
    -> db.escape_literal db.list {"hello", "world", db.TRUE}
    "('hello', 'world', TRUE)"
  }

  {
    -> db.escape_literal db.list {"foo", db.raw "lower(name)"}
    "('foo', lower(name))"
  }

  {
    -> db.escape_literal db.array {1,2,3,4,5}
    "ARRAY[1,2,3,4,5]"
  }

  {
    -> db.interpolate_query "select * from cool where hello = ?", "world"
    "select * from cool where hello = 'world'"
  }

  {
    -> db.encode_values(value_table)
    [[("hello", "age") VALUES ('world', 34)]]
    [[("age", "hello") VALUES (34, 'world')]]
  }

  {
    -> db.encode_assigns(value_table)
    [["hello" = 'world', "age" = 34]]
    [["age" = 34, "hello" = 'world']]
  }

  {
    -> db.encode_assigns thing: db.NULL
    [["thing" = NULL]]
  }

  {
    -> db.encode_clause thing: db.NULL
    [["thing" IS NULL]]
  }

  {
    -> db.encode_clause cool: true, id: db.list {1,2,3,5}
    [["id" IN (1, 2, 3, 5) AND "cool" = TRUE]]
    [["cool" = TRUE AND "id" IN (1, 2, 3, 5)]]
  }

  {
    -> db.interpolate_query "update items set x = ?", db.raw"y + 1"
    "update items set x = y + 1"
  }

  {
    -> db.interpolate_query "update items set x = false where y in ?", db.list {"a", "b"}
    "update items set x = false where y in ('a', 'b')"
  }


  {
    -> db.select "* from things where id = ?", "cool days"
    [[SELECT * from things where id = 'cool days']]
  }

  {
    -> db.insert "cats", age: 123, name: "catter"
    [[INSERT INTO "cats" ("name", "age") VALUES ('catter', 123)]]
    [[INSERT INTO "cats" ("age", "name") VALUES (123, 'catter')]]
  }

  {
    -> db.update "cats", { age: db.raw"age - 10" }, "name = ?", "catter"
    [[UPDATE "cats" SET "age" = age - 10 WHERE name = 'catter']]
  }

  {
    -> db.update "cats", { age: db.raw"age - 10" }, { name: db.NULL }
    [[UPDATE "cats" SET "age" = age - 10 WHERE "name" IS NULL]]
  }

  {
    -> db.update "cats", { age: db.NULL }, { name: db.NULL }
    [[UPDATE "cats" SET "age" = NULL WHERE "name" IS NULL]]
  }

  {
    -> db.update "cats", { color: "red" }, { weight: 1200, length: 392 }
    [[UPDATE "cats" SET "color" = 'red' WHERE "weight" = 1200 AND "length" = 392]]
    [[UPDATE "cats" SET "color" = 'red' WHERE "length" = 392 AND "weight" = 1200]]
  }

  {
    -> db.update "cats", { color: "red" }, { weight: 1200, length: 392 }, "weight", "color"
    [[UPDATE "cats" SET "color" = 'red' WHERE "weight" = 1200 AND "length" = 392 RETURNING "weight", "color"]]
    [[UPDATE "cats" SET "color" = 'red' WHERE "length" = 392 AND "weight" = 1200 RETURNING "weight", "color"]]
  }

  {
    -> db.update "cats", { age: db.NULL }, { name: db.NULL }, db.raw "*"
    [[UPDATE "cats" SET "age" = NULL WHERE "name" IS NULL RETURNING *]]
  }

  {
    -> db.delete "cats"
    [[DELETE FROM "cats"]]
  }

  {
    -> db.delete "cats", "name = ?", "rump"
    [[DELETE FROM "cats" WHERE name = 'rump']]
  }

  {
    -> db.delete "cats", name: "rump"
    [[DELETE FROM "cats" WHERE "name" = 'rump']]
  }

  {
    -> db.delete "cats", name: "rump", dad: "duck"
    [[DELETE FROM "cats" WHERE "name" = 'rump' AND "dad" = 'duck']]
    [[DELETE FROM "cats" WHERE "dad" = 'duck' AND "name" = 'rump']]
  }

  {
    -> db.delete "cats", { color: "red" }, "name", "color"
    [[DELETE FROM "cats" WHERE "color" = 'red' RETURNING "name", "color"]]
  }

  {
    -> db.delete "cats", { color: "red" }, db.raw "*"
    [[DELETE FROM "cats" WHERE "color" = 'red' RETURNING *]]
  }

  {
    -> db.insert "cats", { hungry: true }
    [[INSERT INTO "cats" ("hungry") VALUES (TRUE)]]
  }


  {
    -> db.insert "cats", { age: 123, name: "catter" }, "age"
    [[INSERT INTO "cats" ("name", "age") VALUES ('catter', 123) RETURNING "age"]]
    [[INSERT INTO "cats" ("age", "name") VALUES (123, 'catter') RETURNING "age"]]
  }

  {
    -> db.insert "cats", { age: 123, name: "catter" }, "age", "name"
    [[INSERT INTO "cats" ("name", "age") VALUES ('catter', 123) RETURNING "age", "name"]]
    [[INSERT INTO "cats" ("age", "name") VALUES (123, 'catter') RETURNING "age", "name"]]
  }


  -- lapis.db.postgres.schema

  {
    -> schema.add_column "hello", "dads", schema.types.integer
    [[ALTER TABLE "hello" ADD COLUMN "dads" integer NOT NULL DEFAULT 0]]
  }

  {
    -> schema.rename_column "hello", "dads", "cats"
    [[ALTER TABLE "hello" RENAME COLUMN "dads" TO "cats"]]
  }

  {
    -> schema.drop_column "hello", "cats"
    [[ALTER TABLE "hello" DROP COLUMN "cats"]]
  }

  {
    -> schema.rename_table "hello", "world"
    [[ALTER TABLE "hello" RENAME TO "world"]]
  }

  {
    -> tostring schema.types.integer
    "integer NOT NULL DEFAULT 0"
  }

  {
    -> tostring schema.types.integer null: true
    "integer DEFAULT 0"
  }

  {
    -> tostring schema.types.integer null: true, default: 100, unique: true
    "integer DEFAULT 100 UNIQUE"
  }

  {
    -> tostring schema.types.integer array: true, null: true, default: '{1}', unique: true
    "integer[] DEFAULT '{1}' UNIQUE"
  }

  {
    -> tostring schema.types.text array: true, null: false
    "text[] NOT NULL"
  }

  {
    -> tostring schema.types.text array: true, null: true
    "text[]"
  }

  {
    -> tostring schema.types.integer array: 1
    "integer[] NOT NULL"
  }

  {
    -> tostring schema.types.integer array: 3
    "integer[][][] NOT NULL"
  }

  {
    -> tostring schema.types.serial
    "serial NOT NULL"
  }

  {
    -> tostring schema.types.time
    "timestamp NOT NULL"
  }

  {
    -> tostring schema.types.time timezone: true
    "timestamp with time zone NOT NULL"
  }

  {
    ->
      import foreign_key, boolean, varchar, text from schema.types
      schema.create_table "user_data", {
        {"user_id", foreign_key}
        {"email_verified", boolean}
        {"password_reset_token", varchar null: true}
        {"data", text}
        "PRIMARY KEY (user_id)"
      }

    [[CREATE TABLE "user_data" (
  "user_id" integer NOT NULL,
  "email_verified" boolean NOT NULL DEFAULT FALSE,
  "password_reset_token" character varying(255),
  "data" text NOT NULL,
  PRIMARY KEY (user_id)
)]]
  }

  {
    ->
      import foreign_key, boolean, varchar, text from schema.types
      schema.create_table "join_stuff", {
        {"hello_id", foreign_key}
        {"world_id", foreign_key}
      }, if_not_exists: true

    [[CREATE TABLE IF NOT EXISTS "join_stuff" (
  "hello_id" integer NOT NULL,
  "world_id" integer NOT NULL
)]]
  }


  {
    -> schema.drop_table "user_data"
    [[DROP TABLE IF EXISTS "user_data"]]
  }

  {
    -> schema.create_index "user_data", "thing"
    [[CREATE INDEX "user_data_thing_idx" ON "user_data" ("thing")]]
  }

  {
    -> schema.create_index "user_data", "thing", unique: true
    [[CREATE UNIQUE INDEX "user_data_thing_idx" ON "user_data" ("thing")]]
  }

  {
    -> schema.create_index "user_data", "thing", unique: true, index_name: "good_idx"
    [[CREATE UNIQUE INDEX "good_idx" ON "user_data" ("thing")]]
  }

  {
    -> schema.create_index "user_data", "thing", if_not_exists: true
    [[CREATE INDEX IF NOT EXISTS "user_data_thing_idx" ON "user_data" ("thing")]]
  }

  {
    -> schema.create_index "user_data", "thing", unique: true, where: "age > 100"
    [[CREATE UNIQUE INDEX "user_data_thing_idx" ON "user_data" ("thing") WHERE age > 100]]
  }

  {
    -> schema.create_index "users", "friend_id", tablespace: "farket"
    [[CREATE INDEX "users_friend_id_idx" ON "users" ("friend_id") TABLESPACE "farket"]]
  }

  {
    -> schema.create_index "user_data", "one", "two"
    [[CREATE INDEX "user_data_one_two_idx" ON "user_data" ("one", "two")]]
  }

  {
    -> schema.create_index "user_data", db.raw("lower(name)"), "height"
    [[CREATE INDEX "user_data_lower_name_height_idx" ON "user_data" (lower(name), "height")]]
  }

  {
    -> schema.drop_index "user_data", "one", "two", "three"
    [[DROP INDEX IF EXISTS "user_data_one_two_three_idx"]]
  }

  {
    -> schema.drop_index index_name: "hello_world_idx"
    [[DROP INDEX IF EXISTS "hello_world_idx"]]
  }
  {
    -> schema.drop_index "user_data", "one", "two", "three", cascade: true
    [[DROP INDEX IF EXISTS "user_data_one_two_three_idx" CASCADE]]
  }

  {
    -> schema.drop_index "users", "height", { index_name: "user_tallness_idx", unique: true }
    [[DROP INDEX IF EXISTS "user_tallness_idx"]]
  }

  {
    -> db.parse_clause ""
    {}
  }

  {
    -> db.parse_clause "where something = TRUE"
    {
      where: "something = TRUE"
    }
  }

  {
    -> db.parse_clause "where something = TRUE order by things asc"
    {
      where: "something = TRUE "
      order: "things asc"
    }
  }


  {
    -> db.parse_clause "where something = 'order by cool' having yeah order by \"limit\" asc"
    {
      having: "yeah "
      where: "something = 'order by cool' "
      order: '"limit" asc'
    }
  }

  {
    -> db.parse_clause "where not exists(select 1 from things limit 100)"
    {
      where: "not exists(select 1 from things limit 100)"
    }
  }

  {
    -> db.parse_clause "order by color asc"
    {
      order: "color asc"
    }
  }

  {
    -> db.parse_clause "ORDER BY color asc"
    {
      order: "color asc"
    }
  }

  {
    -> db.parse_clause "group BY height"
    {
      group: "height"
    }
  }

  {
    -> db.parse_clause "where x = limitx 100"
    {
      where: "x = limitx 100"
    }
  }

  {
    -> db.parse_clause "join dads on color = blue where hello limit 10"
    {
      limit: "10"
      where: "hello "
      join: {
        {"join", " dads on color = blue "}
      }
    }
  }

  {
    -> db.parse_clause "inner join dads on color = blue left outer join hello world where foo"
    {
      where: "foo"
      join: {
        {"inner join", " dads on color = blue "}
        {"left outer join", " hello world "}
      }
    }
  }

  {
    -> schema.gen_index_name "hello", "world"
    "hello_world_idx"
  }

  {
    -> schema.gen_index_name "yes", "please", db.raw "upper(dad)"
    "yes_please_upper_dad_idx"
  }

  {
    -> schema.gen_index_name "hello", "world", index_name: "override_me_idx"
    "override_me_idx"
  }

  {
    -> db.encode_case("x", { a: "b" })
    [[CASE x
WHEN 'a' THEN 'b'
END]]
  }

  {
    -> db.encode_case("x", { a: "b", foo: true })
    [[CASE x
WHEN 'a' THEN 'b'
WHEN 'foo' THEN TRUE
END]]
    [[CASE x
WHEN 'foo' THEN TRUE
WHEN 'a' THEN 'b'
END]]
  }


  {
    -> db.encode_case("x", { a: "b" }, false)
    [[CASE x
WHEN 'a' THEN 'b'
ELSE FALSE
END]]
  }

  {
    -> db.is_encodable "hello"
    true
  }

  {
    -> db.is_encodable 2323
    true
  }

  {
    -> db.is_encodable true
    true
  }

  {
    -> db.is_encodable ->
    false
  }

  {
    ->
      if _G.newproxy
        db.is_encodable newproxy!
      else
        -- cjson.empty_array is a userdata
        db.is_encodable require("cjson").empty_array
    false
  }

  {
    -> db.is_encodable db.array {1,2,3}
    true
  }

  {
    -> db.is_encodable db.NULL
    true
  }

  {
    -> db.is_encodable db.TRUE
    true
  }

  {
    -> db.is_encodable db.FALSE
    true
  }

  {
    -> db.is_encodable {}
    false
  }

  {
    -> db.is_encodable nil
    false
  }

  {
    -> db.is_raw "hello"
    false
  }

  {
    -> db.is_raw db.raw "hello wrold"
    true
  }

  {
    -> db.is_raw db.list {1,2,3}
    false
  }
}


local old_query_fn
describe "lapis.db.postgres", ->
  setup ->
    old_query_fn = db.set_backend "raw", (q) -> q

  teardown ->
    db.set_backend "raw", old_query_fn

  for group in *tests
    it "should match", ->
      output = group[1]!
      if #group > 2
        assert.one_of output, { unpack group, 2 }
      else
        assert.same group[2], output


  describe "encode_assigns", ->
    sorted_pairs!

    it "writes output to buffer", ->
      buffer = {"hello"}

      -- nothing is returned when using buffer
      assert.same nil, (db.encode_assigns {
        one: "two"
        zone: 55
        age: db.NULL
      }, buffer)


      assert.same {
        "hello"
        '"age"', " = ", "NULL"
        ", "
        '"one"', " = ", "'two'"
        ", "
        '"zone"', " = ", "55"
      }, buffer

    it "fails when t is empty, buffer unchanged", ->
      buffer = {"hello"}

      assert.has_error(
        -> db.encode_assigns {}, buffer
        "encode_assigns passed an empty table"
      )

      assert.same { "hello" }, buffer

  describe "encode_clause", ->
    sorted_pairs!

    it "writes output to buffer", ->
      buffer = {"hello"}

      -- nothing is returned when using buffer
      assert.same nil, (db.encode_clause {
        hello: "world"
        lion: db.NULL
      }, buffer)

      assert.same {
        "hello"
        '"hello"', " = ", "'world'"
        " AND "
        '"lion"', " IS NULL"
      }, buffer

    it "fails when t is empty, buffer unchanged", ->
      buffer = {"hello"}

      assert.has_error(
        -> db.encode_clause {}, buffer
        "encode_clause passed an empty table"
      )

      assert.same { "hello" }, buffer

  describe "encode_values", ->
    sorted_pairs!

    it "writes output to buffer", ->
      buffer = {"hello"}

      -- nothing is returned when using buffer
      assert.same nil, (db.encode_values {
        hello: "world"
        lion: db.NULL
      }, buffer)

      assert.same {
        "hello"
        '(',
        '"hello"', ', ', '"lion"'
        ') VALUES ('
        "'world'", ', ', 'NULL'
        ')'
      }, buffer

    it "fails when t is empty, buffer unchanged", ->
      buffer = {"hello"}

      assert.has_error(
        -> db.encode_values {}, buffer
        "encode_values passed an empty table"
      )

      assert.same { "hello" }, buffer
