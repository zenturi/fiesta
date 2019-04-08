package fiesta.math;

class Sphere {
	public var center:Vector4;
	public var radius:Float = 0;

	public function new() {
		this.center = new Vector4();
	}

	public function clone() {
		var sphere = new Sphere();
		sphere.copy(this);
		return sphere;
	}

	public function copy(sphere) {
		this.center.copyFrom(sphere.center);
		this.radius = sphere.radius;
		return this;
	}

	public function fromPoints(points:Array<Float>) {
		var center = this.center;
		var maxSquaredRadius:Float = 0;
		var i = 0;
		while (i < points.length) {
			var x = points[i] - center.x;
			var y = points[i + 1] - center.y;
			var z = points[i + 2] - center.z;
			maxSquaredRadius = Math.max(x * x + y * y + z * z, maxSquaredRadius);

			i += 3;
		}

		this.radius = Math.sqrt(maxSquaredRadius);
		return this;
	}


    private static var temp:Vector4 = new Vector4();

	public function transformMat4(mat4:Matrix4) {
		this.center.transform(mat4);
        var scale = mat4.position;
		
        this.fromPoints([scale.x, scale.y, scale.z]);
		return this;
	}
}
