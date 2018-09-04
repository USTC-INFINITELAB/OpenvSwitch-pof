 
 Notification:
 
   I have fix this problem that users have to modify ```./include/odp-netlik.h``` manually. ```odp-netlink.h```
 is auto-make from ```<linux/openvswitch.h>```, so I modify the above file. Therefore, skip steps below.
 
 ---
 
 # odp-netlink.h
 
 Because 'odp-netlink.h' is read-only file, while the user space communicates with kernel space using the netlink protocol. 
 In order to support ovs-pof, you should change the file 'odp-netlink.h'. Git will not follow the read-only file, so I add 
 this README.md to remind you to add some neccessary content in odp-netlink.h. If you ignored it, you would encounter the 
 compilation problem and cannot see the POF functions run.

 The instructions are listed as follow:

 ## 1. change file rights

 The odp-netlink.h is read-only file, you should change it to writable file first.

 ```
 sudo chmod 777 odp-netlink.h
 ```
 
 ## 2. add pof action key struct
 
 Then you should add some missed struct in odp-netlink.h. Take modify_filed action as an example.
 
 - append 'OVS_KET_ATTR_*' in 'enum ovs_key_attr'
 
 ```
 enum ovs_key_attr {
 	OVS_KEY_ATTR_UNSPEC,
 	OVS_KEY_ATTR_ENCAP,	/* Nested set of encapsulated attributes. */
 	OVS_KEY_ATTR_PRIORITY,  /* u32 skb->priority */
 	OVS_KEY_ATTR_IN_PORT,   /* u32 OVS dp port number */
 	...
 	OVS_KEY_ATTR_MODIFY_FIELD,   // appended by tsf
 ```
 
 - add struct ovs_ket_set_field

 This structure is passed from user space with "odp-util.c/commit()" function. "odp-execute.c/odp_execute_actions()" function will 
 modify packets according to ```struct ovs_key_modify_field```.
 ```
 struct ovs_key_modify_field {  // added by tsf
	 uint16_t field_id;
	 uint16_t offset;
	 uint16_t len;
	 uint8_t value[16];
 };
```
 
 ## 3. the content that you should append
 
 ovs-pof has already supports actions like ```set_field```, ```modify_field```, ```add_field``` and ```delete_field``` which
 will change the original packets, so you have to add those missed struct in odp-netlink.h. The other actions such as 
 ```output```,  ```goto_table``` and ```drop``` are also supported by ovs-pof.
 
 - enum ovs_key_attr
 
 ```
 enum ovs_key_attr {
 	OVS_KEY_ATTR_UNSPEC,
 	OVS_KEY_ATTR_ENCAP,	/* Nested set of encapsulated attributes. */
 	OVS_KEY_ATTR_PRIORITY,  /* u32 skb->priority */
 	OVS_KEY_ATTR_IN_PORT,   /* u32 OVS dp port number */
 	...
 	OVS_KEY_ATTR_SET_FIELD,
 	OVS_KEY_ATTR_MODIFY_FIELD,
 	OVS_KEY_ATTR_ADD_FIELD,
 	OVS_KEY_ATTR_DELETE_FIELD,
 	...
 	}
 ```
 
 - struct ovs_key_*
 
 ```
 struct ovs_key_set_field {
 	uint16_t field_id;
 	uint16_t offset;
 	uint16_t len;
 	uint8_t value[16];
 };
 
 struct ovs_key_modify_field {
 	uint16_t field_id;
 	uint16_t offset;
 	uint16_t len;
 	uint8_t value[16];
 };
 
struct ovs_key_add_field {
	uint16_t field_id;    /* tsf: if field_id=0xffff, add_INT; otherwise, add_field */
	uint16_t offset;
	uint16_t len;
	uint8_t value[16];    /* tsf: the static fields for all value array or INT intent for value[0]*/

	/* tsf: INT fields, bitmap in value[0], can be combined with more fields whose bit is 1. */
	uint64_t device_id;  /* value[0]=0x01 */
	uint8_t in_port;     /* value[0]=0x02 */
	uint8_t out_port;    /* value[0]=0x04 */
	/*uint64_t pre_time;*/   /* value[0]=0x08, get in odp_pof_add_field */
	/*uint64_t now_time;*/   /* value[0]=0x10, get in odp_pof_add_field */
};
 
 struct ovs_key_delete_field {
 	uint16_t offset;
 	uint16_t len;
 	uint16_t len_type;
 };
 ```